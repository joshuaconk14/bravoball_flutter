import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/user_manager_service.dart';
import '../../services/email_verification_service.dart';
import '../../models/email_verification_model.dart';

class EditDetailsView extends StatefulWidget {
  const EditDetailsView({Key? key}) : super(key: key);

  @override
  State<EditDetailsView> createState() => _EditDetailsViewState();
}

class _EditDetailsViewState extends State<EditDetailsView> {
  final EmailVerificationService _emailVerificationService = EmailVerificationService.shared;
  late EmailVerificationModel _emailVerificationModel;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _emailVerificationModel = EmailVerificationModel();
    // Set current email from user manager
    final userManager = Provider.of<UserManagerService>(context, listen: false);
    _emailVerificationModel.currentEmail = userManager.email;
  }

  @override
  void dispose() {
    _emailVerificationModel.dispose();
    super.dispose();
  }

  Color _getMessageColor(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Success messages
    if (lowerMessage.contains('sent') ||
        lowerMessage.contains('verified') ||
        lowerMessage.contains('successfully')) {
      return Colors.green;
    }
    
    // Error messages
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _emailVerificationModel,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.primaryDark),
            onPressed: () {
              _emailVerificationModel.resetEmailVerificationState();
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            'Edit Details',
            style: TextStyle(
              color: AppTheme.primaryDark,
              fontFamily: AppTheme.fontPoppins,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16), // Reduced from 20
                
                // Step content
                Consumer<EmailVerificationModel>(
                  builder: (context, model, child) {
                    switch (model.emailVerificationStep) {
                      case 1:
                        return _buildEmailStep();
                      case 2:
                        return _buildCodeStep();
                      default:
                        return _buildEmailStep();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 1: Current Email Display and New Email Input
  Widget _buildEmailStep() {
    return Column(
      children: [
        Text(
          'Update Your Email',
          style: AppTheme.headlineLarge.copyWith(
            fontSize: 22,
            color: AppTheme.primaryDark,
            fontFamily: AppTheme.fontPoppins,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8), // Reduced spacing
        
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return Text(
              'Current email: ${Provider.of<UserManagerService>(context).email}',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
                fontFamily: AppTheme.fontPoppins,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Enter your new email address and we\'ll send you a verification code.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
            fontFamily: AppTheme.fontPoppins,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 24), // Reduced from AppTheme.spacingLarge
        
        // New Email Field
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return TextField(
              onChanged: (value) => model.newEmail = value,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'New Email',
                hintText: 'Enter your new email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(16),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Message
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            if (model.emailVerificationMessage.isEmpty) {
              return const SizedBox();
            }
            
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _getMessageColor(model.emailVerificationMessage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getMessageColor(model.emailVerificationMessage).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMessageColor(model.emailVerificationMessage) == Colors.green
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _getMessageColor(model.emailVerificationMessage),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.emailVerificationMessage,
                      style: AppTheme.bodySmall.copyWith(
                        color: _getMessageColor(model.emailVerificationMessage),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Send Verification Button
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: model.newEmail.isEmpty || _isSending
                    ? null
                    : () async {
                        setState(() => _isSending = true);
                        await _emailVerificationService.sendEmailVerification(
                          model.newEmail,
                          model,
                        );
                        setState(() => _isSending = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Send Verification Code',
                        style: AppTheme.buttonTextMedium,
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Step 2: Code Verification
  Widget _buildCodeStep() {
    return Column(
      children: [
        Text(
          'Enter Verification Code',
          style: AppTheme.headlineLarge.copyWith(
            fontSize: 22,
            color: AppTheme.primaryDark,
            fontFamily: AppTheme.fontPoppins,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return Text(
              'We\'ve sent a 6-digit code to ${model.newEmail}',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
                fontFamily: AppTheme.fontPoppins,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Code Field
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return TextField(
              onChanged: (value) {
                // Limit to 6 digits
                if (value.length <= 6) {
                  model.emailVerificationCode = value;
                }
              },
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: '6-digit code',
                hintText: 'Enter verification code',
                prefixIcon: const Icon(Icons.security),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(16),
                counterText: '', // Hide character counter
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Message
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            if (model.emailVerificationMessage.isEmpty) {
              return const SizedBox();
            }
            
            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _getMessageColor(model.emailVerificationMessage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getMessageColor(model.emailVerificationMessage).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMessageColor(model.emailVerificationMessage) == Colors.green
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _getMessageColor(model.emailVerificationMessage),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.emailVerificationMessage,
                      style: AppTheme.bodySmall.copyWith(
                        color: _getMessageColor(model.emailVerificationMessage),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Verify Code Button
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: model.emailVerificationCode.length != 6 || _isSending
                    ? null
                    : () async {
                        setState(() => _isSending = true);
                        await _emailVerificationService.verifyEmailAndUpdate(
                          model.emailVerificationCode,
                          model,
                          onSuccess: () {
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email updated successfully!'),
                                backgroundColor: AppTheme.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            
                            // Close the view
                            Navigator.of(context).pop();
                          },
                        );
                        setState(() => _isSending = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Verify & Update Email',
                        style: AppTheme.buttonTextMedium,
                      ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Resend Code Button
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isSending
                    ? null
                    : () async {
                        setState(() => _isSending = true);
                        await _emailVerificationService.sendEmailVerification(
                          model.newEmail,
                          model,
                        );
                        setState(() => _isSending = false);
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryYellow,
                  side: BorderSide(color: AppTheme.primaryYellow),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Resend Code',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.primaryYellow,
                    fontFamily: AppTheme.fontPoppins,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 