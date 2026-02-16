import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart';

class CreditsView extends StatelessWidget {
  const CreditsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Credits & Attributions',
          style: AppTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Content wrapped in white container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Credits & Attributions',
                      style: AppTheme.headlineLarge.copyWith(
                        fontSize: 24,
                        color: AppTheme.primaryDark,
                        fontFamily: AppTheme.fontPoppins,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Icons Section
                    _buildSection(
                      'Icons',
                      'The following soccer player icons used in this app are provided by Flaticon and are used in accordance with their licensing terms:',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildCreditItem(
                      'BZZRINCANTATION',
                      'www.flaticon.com',
                    ),
                    
                    _buildCreditItem(
                      'Park Jisun',
                      'www.flaticon.com',
                    ),
                    
                    _buildCreditItem(
                      'Freepik',
                      'www.flaticon.com',
                    ),
                    
                    _buildCreditItem(
                      'Futuer',
                      'www.flaticon.com',
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Additional Credits Section
                    _buildSection(
                      'Additional Resources',
                      'Bravo animation and tab view icons were created by Co-Founder, Joshua Conklin, using Rive app.\n\nWe are grateful to the open-source community and third-party services that make BravoBall possible.',
                    ),
                    
                    const SizedBox(height: 12),
                    
                    _buildCreditItem(
                      'Flutter',
                      'Google - flutter.dev',
                    ),
                    
                    _buildCreditItem(
                      'Rive Animations',
                      'Rive - rive.app',
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.primaryDark,
              fontFamily: AppTheme.fontPoppins,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          
          const SizedBox(height: 10),
          
          Text(
            content,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryGray,
              fontFamily: AppTheme.fontPoppins,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditItem(String creator, String source) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryGray,
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: 'Icons made by $creator from ',
                  ),
                  TextSpan(
                    text: source,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
