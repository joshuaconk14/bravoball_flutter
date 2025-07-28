import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../config/app_config.dart';
import '../../services/test_data_service.dart';
import '../../services/app_state_service.dart';
import '../../utils/skill_utils.dart'; // ✅ ADDED: Import centralized skill utilities

class DebugSettingsView extends StatefulWidget {
  const DebugSettingsView({Key? key}) : super(key: key);

  @override
  State<DebugSettingsView> createState() => _DebugSettingsViewState();
}

class _DebugSettingsViewState extends State<DebugSettingsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Debug Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Debug Mode Status
            _buildStatusCard(),
            
            const SizedBox(height: 24),
            
            // Environment Settings
            _buildEnvironmentSection(),
            
            const SizedBox(height: 24),
            
            // Test Data Actions
            _buildTestDataSection(),
            
            const SizedBox(height: 24),
            
            // Debug Info
            _buildDebugInfoSection(),
            
            const SizedBox(height: 24),
            
            // Developer Actions
            _buildDeveloperActionsSection(),
            
            const SizedBox(height: 24),
            
            // Streak Testing Section (always show for debugging)
            _buildStreakTestingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isTestMode = AppConfig.useTestData;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTestMode 
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isTestMode ? Icons.bug_report : Icons.cloud,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTestMode ? 'Test Data Mode' : 'Backend Data Mode',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isTestMode ? 'Using local test data' : 'Connected to: ${AppConfig.baseUrl}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Text(
            isTestMode 
                ? 'To switch to backend data, change AppConfig.appDevCase to 1, 2, or 3 in app_config.dart and hot restart.'
                : 'To switch to test data, change AppConfig.appDevCase to 0 in app_config.dart and hot restart.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Environment Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildInfoRow('Current Environment', AppConfig.environmentName),
              const Divider(),
              _buildInfoRow('Base URL', AppConfig.baseUrl),
              const Divider(),
              _buildInfoRow('Debug Logging', AppConfig.logApiCalls ? 'Enabled' : 'Disabled'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestDataSection() {
    if (!AppConfig.useTestData) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Data Actions',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Column(
          children: [
            _buildActionButton(
              title: 'Load Test Session',
              subtitle: 'Generate ${AppConfig.testDrillCount} test drills',
              icon: Icons.fitness_center,
              onTap: () => _loadTestSession(),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionButton(
              title: 'Clear Session Data',
              subtitle: 'Reset all session progress',
              icon: Icons.clear_all,
              onTap: () => _clearSessionData(),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionButton(
              title: 'Generate Test Progress',
              subtitle: 'Add sample progress data',
              icon: Icons.trending_up,
              onTap: () => _generateTestProgress(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDebugInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Debug Information',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'System Info',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyDebugInfo(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Copy',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                AppConfig.debugInfo.trim(),
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Developer Actions',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Column(
          children: [
            _buildActionButton(
              title: 'Test API Connection',
              subtitle: 'Check backend connectivity',
              icon: Icons.network_check,
              onTap: () => _testApiConnection(),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionButton(
              title: 'View Test Data',
              subtitle: 'Show all test drills',
              icon: Icons.view_list,
              onTap: () => _showTestDataDialog(),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionButton(
              title: 'Force Crash',
              subtitle: 'Test error handling',
              icon: Icons.warning,
              color: Colors.red,
              onTap: () => _forceCrash(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakTestingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Streak Testing',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Column(
          children: [
            _buildActionButton(
              title: 'Reset Streak',
              subtitle: 'Set current streak to 0',
              icon: Icons.refresh,
              onTap: () => _resetStreak(),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionButton(
              title: 'Add Days to Streak',
              subtitle: 'Increment current streak by 1',
              icon: Icons.add_circle,
              onTap: () => _addDaysToStreak(),
            ),
            
            const SizedBox(height: 8),
            
            _buildActionButton(
              title: 'Add Completed Sessions',
              subtitle: 'Simulate adding completed sessions',
              icon: Icons.check_circle,
              onTap: () => _addCompletedSessions(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryYellow).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color ?? AppTheme.primaryYellow,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _loadTestSession() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.loadTestSession();
    
    TestDataService.debugLog('Loading test session with ${AppConfig.testDrillCount} drills');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test session loaded with ${AppConfig.testDrillCount} drills'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearSessionData() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.clearAllData();
    
    TestDataService.debugLog('Clearing all session data');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session data cleared'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _generateTestProgress() {
    TestDataService.debugLog('Generating test progress data');
    
    // Generate test progress data asynchronously
    _loadTestProgressData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating test progress data...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  Future<void> _loadTestProgressData() async {
    try {
      final testProgress = await TestDataService.getTestUserProgress();
      final weeklyProgress = testProgress['weeklyProgress'] as Map<String, dynamic>;
      final skillProgress = testProgress['skillProgress'] as Map<String, dynamic>;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generated progress for ${weeklyProgress.length} days and ${skillProgress.length} skills'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate test progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testApiConnection() {
    TestDataService.debugLog('Testing API connection to ${AppConfig.baseUrl}');
    
    // Simulate API test
    TestDataService.simulateApiDelay('Connection test', milliseconds: 2000).then((result) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API connection test completed: $result'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API connection failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing connection to ${AppConfig.baseUrl}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showTestDataDialog() {
    final testDrills = TestDataService.getTestDrills();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Data'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: testDrills.length,
            itemBuilder: (context, index) {
              final drill = testDrills[index];
              return ListTile(
                title: Text(drill.title),
                subtitle: Text('${SkillUtils.formatSkillForDisplay(drill.skill)} - ${drill.duration}min'), // ✅ UPDATED: Use centralized skill formatting
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _forceCrash() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Crash'),
        content: const Text('This will intentionally crash the app to test error handling. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              throw Exception('Debug: Intentional crash for testing');
            },
            child: const Text('Crash', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _resetStreak() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.resetStreak();
    TestDataService.debugLog('Streak reset to 0');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Streak reset to 0'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _addDaysToStreak() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.incrementStreak();
    TestDataService.debugLog('Streak incremented by 1');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Streak incremented by 1'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addCompletedSessions() {
    final appState = Provider.of<AppStateService>(context, listen: false);
    appState.addCompletedSessions(5); // Simulate adding 5 completed sessions
    TestDataService.debugLog('Simulated adding 5 completed sessions');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated adding 5 completed sessions'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _copyDebugInfo() {
    Clipboard.setData(ClipboardData(text: AppConfig.debugInfo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug info copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 