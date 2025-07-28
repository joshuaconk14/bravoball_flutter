import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart'; // ✅ ADDED: Import HapticUtils

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray, // ✅ UPDATED: Changed to grayish background
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary, // ✅ UPDATED: White AppBar background
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDark), // ✅ UPDATED: Back arrow instead of close
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Privacy Policy',
          style: AppTheme.titleLarge, // ✅ UPDATED: Use consistent title style
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
                      'Privacy Policy',
                      style: AppTheme.headlineLarge.copyWith(
                        fontSize: 24,
                        color: AppTheme.primaryDark,
                        fontFamily: AppTheme.fontPoppins,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Last updated: May 2025',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryGray,
                        fontFamily: AppTheme.fontPoppins,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Content
                    _buildSection(
                      '1. Introduction',
                      'BravoBall (the "App") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our App.',
                    ),
                    
                    _buildSection(
                      '2. Information We Collect',
                      'We collect information you provide directly to us, such as your name, email address, and soccer training preferences including your position, experience level, training goals, available equipment, and training schedule. We also collect usage data to improve your training experience and track your progress.',
                    ),
                    
                    _buildSection(
                      '3. How We Use Your Information',
                      'We use your information to: (a) create personalized training sessions; (b) track your progress and achievements; (c) save your training preferences and history; (d) communicate with you about your training; (e) improve our training programs; and (f) ensure the security of your account.',
                    ),
                    
                    _buildSection(
                      '4. Sharing Your Information',
                      'We do not sell your personal information. We may share your information with trusted third-party service providers who assist us in operating the App, as required by law, or to protect our rights. All third parties are required to protect your information and use it only for the purposes we specify.',
                    ),
                    
                    _buildSection(
                      '5. Data Security',
                      'We implement industry-standard security measures to protect your personal information and training data. This includes secure storage of your account credentials, encrypted data transmission, and regular security updates. Your training progress and preferences are stored securely on our servers.',
                    ),
                    
                    _buildSection(
                      '6. Your Rights',
                      'You may access, update, or delete your personal information at any time by contacting us at team@conklinofficial.com. You may also request that we stop using your information for certain purposes.',
                    ),
                    
                    _buildSection(
                      '7. Children\'s Privacy',
                      'BravoBall is designed to be accessible to soccer players of all ages. For users under 13, we recommend parental supervision and guidance. Parents or guardians can contact us at team@conklinofficial.com to manage their child\'s account and data.',
                    ),
                    
                    _buildSection(
                      '8. Changes to This Policy',
                      'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy in the App. Your continued use of the App after changes are posted constitutes your acceptance of those changes.',
                    ),
                    
                    _buildSection(
                      '9. Contact Us',
                      'If you have any questions or concerns about this Privacy Policy, please contact us at team@conklinofficial.com.',
                    ),
                    
                    _buildSection(
                      '10. Data Retention',
                      'We retain your personal information for as long as necessary to provide our services and comply with legal obligations. You can request deletion of your data at any time.',
                    ),
                    
                    _buildSection(
                      '11. International Data Transfers',
                      'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data.',
                    ),
                    
                    _buildSection(
                      '12. Third-Party Services',
                      'We use the following third-party services in our app:\n\n• Rive Runtime: For training animations and interactive elements\n• SwiftKeychainWrapper: For secure storage of your account information\n\nWe also use our own backend services to manage your training data, progress tracking, and personalized training sessions. All data is processed in accordance with our privacy standards and applicable laws.',
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
} 