import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../../constants/app_theme.dart';
import '../../services/login_service.dart';
import 'forgot_password_view.dart';
import '../../models/login_state_model.dart';
import '../../widgets/bravo_button.dart';
import '../../utils/haptic_utils.dart';

/// Login View
/// Mirrors Swift LoginView for user authentication UI
class LoginView extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onCancel;

  const LoginView({
    Key? key,
    this.onLoginSuccess,
    this.onCancel,
  }) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginService _loginService = LoginService.shared;
  late LoginStateModel _loginModel;

  @override
  void initState() {
    super.initState();
    _loginModel = LoginStateModel();
  }

  @override
  void dispose() {
    _loginModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _loginModel,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingXLarge),
                
                // Welcome Back Title
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPottaOne,
                    fontSize: 32,
                    color: AppTheme.primaryYellow,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppTheme.spacingXLarge),
                
                // Logo/Animation with Bravo character - no background
                Container(
                  height: 200,
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                  child: const RiveAnimation.asset(
                    'assets/rive/Bravo_Animation.riv',
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingXLarge),
                
                // Login Form
                _buildLoginForm(),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                // Forgot Password Button
                _buildForgotPasswordButton(),
                
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Error Message
                Consumer<LoginStateModel>(
                  builder: (context, model, child) {
                    if (model.errorMessage.isEmpty) {
                      return const SizedBox();
                    }
                    
                    return Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Expanded(
                            child: Text(
                              model.errorMessage,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // Login Button
                _buildLoginButton(),
                
                const SizedBox(height: AppTheme.spacingMedium),
                
                // Cancel Button
                _buildCancelButton(),
                
                const SizedBox(height: AppTheme.spacingXLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email Field
        Consumer<LoginStateModel>(
          builder: (context, model, child) {
            return TextField(
              onChanged: model.setEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              onSubmitted: (_) {
                // Move focus to password field
                FocusScope.of(context).nextFocus();
              },
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.3),
                contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Password Field
        Consumer<LoginStateModel>(
          builder: (context, model, child) {
            return TextField(
              onChanged: model.setPassword,
              obscureText: !model.isPasswordVisible,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                // ✅ IMPROVED: Dismiss keyboard and attempt login
                FocusScope.of(context).unfocus();
                if (model.isFormValid && !model.isLoading) {
                  _handleLogin();
                }
              },
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () {
                    HapticUtils.lightImpact(); // Light haptic for password toggle
                    model.togglePasswordVisibility();
                  },
                  icon: Icon(
                    model.isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.3),
                contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          HapticUtils.lightImpact(); // Light haptic for forgot password
          _handleForgotPassword();
        },
        child: Text(
          'Forgot Password?',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryYellow,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<LoginStateModel>(
      builder: (context, model, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: BravoButton(
              text: model.isLoading ? '' : 'Login',
              onPressed: model.isLoading || !model.isFormValid ? null : () {
                HapticUtils.mediumImpact(); // Medium haptic for login
                _handleLogin();
              },
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: Colors.white,
              disabled: model.isLoading || !model.isFormValid,
              textSize: 18,
              height: 50,
              child: model.isLoading 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : null,
            )
        );
      },
    );
  }

  Widget _buildCancelButton() {
    return Consumer<LoginStateModel>(
      builder: (context, model, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: BravoButton(
            text: 'Cancel',
            onPressed: model.isLoading ? null : () {
              HapticUtils.mediumImpact(); // Medium haptic for cancel
              _handleCancel();
            },
            color: Colors.white,
            backColor: AppTheme.lightGray,
            textColor: AppTheme.primaryYellow,
            disabled: false,
            textSize: 18,
            height: 50,
            borderSide: BorderSide(color: AppTheme.lightGray, width: 2),
          )
        );
      },
    );
  }

  // Action Handlers
  Future<void> _handleLogin() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    
    final success = await _loginService.loginUser(loginModel: _loginModel);
    
    if (success && mounted) {
      // Login successful - call callback
      widget.onLoginSuccess?.call();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login successful!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // Error handling is done in the LoginService and displayed via the error message
  }

  void _handleForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordView(),
      ),
    );
  }

  void _handleCancel() {
    // Clear form and call callback
    _loginModel.resetLoginInfo();
    widget.onCancel?.call();
  }
} 