import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // ✅ ADDED: For SystemChrome orientation locking
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rive/rive.dart';
import 'views/onboarding_view.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/auth/login_view.dart';
import 'views/main_tab_view.dart';
import 'services/app_state_service.dart';
import 'services/api_service.dart';
import 'services/authentication_service.dart';
import 'services/user_manager_service.dart';
import 'services/android_compatibility_service.dart'; // ✅ ADDED: Import Android compatibility service
import 'services/loading_state_service.dart';
import 'constants/app_theme.dart';
import 'config/app_config.dart';
import 'widgets/bravo_loading_indicator.dart';

// Global flag to track intro animation - persists across widget rebuilds
bool _hasShownIntroAnimation = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ ADDED: Lock orientation to portrait only (iPhone-only, portrait-only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Show debug information
  if (kDebugMode) {
    print('🚀 Starting BravoBall Flutter App');
    print('📱 ${AppConfig.debugInfo}');
    print('🌐 Phone Wi-Fi IP: ${AppConfig.phoneWifiIP}');
  }
  
  // ✅ ADDED: Initialize Android compatibility service
  await AndroidCompatibilityService.shared.initialize();
  
  // Initialize services
  ApiService.shared.initialize();
  
  // Initialize the app state service
  await AppStateService.instance.initialize();
  
  // Initialize authentication services
  await UserManagerService.instance.initialize();
  await AuthenticationService.shared.initialize();
  
  if (kDebugMode) {
    print('✅ All services initialized successfully');
    // ✅ ADDED: Log Android debug info if on Android
    AndroidCompatibilityService.shared.logAndroidDebugInfo();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isShowingIntro = false;

  @override
  void initState() {
    super.initState();
    _showIntroIfNeeded();
  }

  void _showIntroIfNeeded() {
    if (!_hasShownIntroAnimation) {
      setState(() {
        _isShowingIntro = true;
        _hasShownIntroAnimation = true; // Set global flag
      });
      
      // Auto-complete intro after 6 seconds
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) {
          setState(() {
            _isShowingIntro = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AppStateService.instance),
        ChangeNotifierProvider.value(value: UserManagerService.instance),
        ChangeNotifierProvider.value(value: AuthenticationService.shared),
        ChangeNotifierProvider.value(value: LoadingStateService.instance),
      ],
      child: MaterialApp(
        title: 'BravoBall',
        theme: AppTheme.lightTheme,
        home: Stack(
          children: [
            // Main app content
            const AuthenticationChecker(),
            
            // Intro animation overlay (only on true app startup)
            if (_isShowingIntro)
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.transparent,
                child: const RiveAnimation.asset(
                  'assets/rive/BravoBall_Intro.riv',
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
        debugShowCheckedModeBanner: false,
        // Show performance overlay if enabled in debug mode
        showPerformanceOverlay: AppConfig.showPerformanceOverlay,
      ),
    );
  }
}

/// Authentication Checker - Simple widget that checks auth state and shows appropriate content
class AuthenticationChecker extends StatelessWidget {
  const AuthenticationChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserManagerService, AuthenticationService>(
      builder: (context, userManager, authService, child) {
        // Show loading screen while checking authentication
        if (authService.isCheckingAuth) {
          return const BravoLoginLoadingIndicator(
            message: 'Welcome back! Checking your credentials...',
          );
        }

        // Return appropriate content based on authentication state
        // ✅ UPDATED: Check for both logged in users AND guest users
        if (userManager.isLoggedIn || userManager.isGuestMode) {
          return const AuthenticatedApp();
        } else {
          return const UnauthenticatedApp();
        }
      },
    );
  }
}

/// Authenticated App - Handles logged-in user flow
class AuthenticatedApp extends StatefulWidget {
  const AuthenticatedApp({super.key});

  @override
  State<AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<AuthenticatedApp> {
  bool _hasLoadedBackendData = false;

  @override
  void initState() {
    super.initState();
    _loadBackendDataIfNeeded();
  }

  void _loadBackendDataIfNeeded() {
    final userManager = UserManagerService.instance;
    final appState = AppStateService.instance;
    
    // ✅ UPDATED: Skip backend data loading for guest users
    if (userManager.isGuestMode) {
      // Guest users don't need backend data, set initial load to false immediately
      appState.setInitialLoadState(false);
      
      if (kDebugMode) {
        print('👤 Guest user detected - skipping backend data load');
      }
      return;
    }
    
    // Load backend data if user has account history and we haven't loaded yet
    if (userManager.userHasAccountHistory && !_hasLoadedBackendData) {
      if (kDebugMode) {
        print('📱 Loading backend data for user: ${userManager.email}');
      }
      
      appState.loadBackendData().then((_) {
        if (mounted) {
          setState(() {
            _hasLoadedBackendData = true;
          });
        }
      });
    } else {
      // If no user history, set isInitialLoad to false immediately
      appState.setInitialLoadState(false);
      
      if (kDebugMode) {
        print('✅ Initialization complete - isInitialLoad set to false (no user history)');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        // Show a smoother loading transition while backend data loads
        if (appState.isInitialLoad) {
          return const BravoLoginLoadingIndicator(
            message: 'Getting everything ready...',
          );
        }
        
        return const MainTabView();
      },
    );
  }
}

/// Unauthenticated App - Handles onboarding and login flow
class UnauthenticatedApp extends StatelessWidget {
  const UnauthenticatedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingFlow();
  }
}

/// Auth Loading Screen - Shows while checking authentication status on app start
/// Now using the enhanced BravoLoadingIndicator
class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BravoLoadingIndicator(
      message: 'Welcome to BravoBall',
      backgroundColor: AppTheme.primaryPurple,
    );
  }
}

// Keep existing MyHomePage for reference/debugging
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (AppConfig.shouldShowDebugMenu) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'DEBUG MODE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConfig.debugInfo,
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
