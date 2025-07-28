import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/haptic_utils.dart'; // ✅ ADDED: Import HapticUtils

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({Key? key}) : super(key: key);

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
          'Terms of Service',
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
                      'Terms of Service',
                      style: AppTheme.headlineLarge.copyWith(
                        fontSize: 24,
                        color: AppTheme.primaryDark,
                        fontFamily: AppTheme.fontPoppins,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Last updated: ${_formatCurrentDate()}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryGray,
                        fontFamily: AppTheme.fontPoppins,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Content
                    _buildSection(
                      '1. Acceptance of Terms',
                      'By accessing or using BravoBall, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree, please do not use the App.',
                    ),
                    
                    _buildSection(
                      '2. Use of the App',
                      'You agree to use the App only for lawful purposes and in accordance with these Terms. You are responsible for maintaining the confidentiality of your account and for all activities that occur under your account.',
                    ),
                    
                    _buildSection(
                      '3. User Content',
                      'You retain ownership of your training data, progress, and preferences. You grant us a non-exclusive license to use this information to provide and improve your training experience. This includes your training history, saved drills, and performance metrics.',
                    ),
                    
                    _buildSection(
                      '4. Prohibited Conduct',
                      'You agree not to: (a) use the App for any unlawful purpose; (b) attempt to gain unauthorized access to any part of the App; (c) interfere with or disrupt the App or its servers; (d) upload viruses or malicious code; (e) share your account credentials; (f) manipulate training data or progress metrics; or (g) violate any applicable laws or regulations.',
                    ),
                    
                    _buildSection(
                      '5. Intellectual Property',
                      'All content, features, and functionality of the App (excluding user content) are the exclusive property of BravoBall and its licensors. You may not copy, modify, or distribute any part of the App without our prior written consent.',
                    ),
                    
                    _buildSection(
                      '6. Termination',
                      'We reserve the right to suspend or terminate your access to the App at any time, without notice, for conduct that we believe violates these Terms or is otherwise harmful to other users or the App.',
                    ),
                    
                    _buildSection(
                      '7. Disclaimer of Warranties',
                      'The App is provided on an "as is" and "as available" basis. We make no warranties, express or implied, regarding the App\'s operation or availability. We do not guarantee that the training programs will achieve specific results, and users should exercise proper judgment and safety precautions while training.',
                    ),
                    
                    _buildSection(
                      '8. Limitation of Liability',
                      'To the fullest extent permitted by law, BravoBall and its affiliates shall not be liable for any indirect, incidental, special, or consequential damages arising out of or in connection with your use of the App. This includes any injuries or accidents that may occur during training exercises. Users are responsible for their own safety and should consult with healthcare professionals before beginning any training program.',
                    ),
                    
                    _buildSection(
                      '9. Changes to Terms',
                      'We may update these Terms of Service from time to time. We will notify you of any material changes by posting the new terms in the App. Your continued use of the App after changes are posted constitutes your acceptance of those changes.',
                    ),
                    
                    _buildSection(
                      '10. Governing Law',
                      'These Terms are governed by the laws of the United States and the State of California, without regard to conflict of law principles.',
                    ),
                    
                    _buildSection(
                      '11. Contact Us',
                      'If you have any questions about these Terms, please contact us at team@conklinofficial.com.',
                    ),
                    
                    _buildSection(
                      '12. Subscription and Payments',
                      'If the App offers subscription services, you agree to pay all fees associated with your subscription. Subscriptions automatically renew unless cancelled.',
                    ),
                    
                    _buildSection(
                      '13. Refund Policy',
                      'Refund requests will be considered on a case-by-case basis. Contact us at team@conklinofficial.com for refund inquiries.',
                    ),
                    
                    _buildSection(
                      '14. Dispute Resolution',
                      'Any disputes shall be resolved through binding arbitration in accordance with the rules of the American Arbitration Association.',
                    ),
                    
                    _buildSection(
                      '15. Training Safety',
                      'You acknowledge that soccer training involves physical activity and potential risks. You agree to: (a) consult with a healthcare professional before beginning any training program; (b) use proper equipment and follow safety guidelines; (c) stop training if you experience pain or discomfort; and (d) take responsibility for your own safety during training sessions.',
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

  String _formatCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
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