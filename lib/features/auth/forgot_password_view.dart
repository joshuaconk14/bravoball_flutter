import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/forgot_password_service.dart';
import '../../models/forgot_password_model.dart';
import '../../widgets/bravo_button.dart'; // ✅ ADDED: Import BravoButton
import '../../utils/haptic_utils.dart'; // ✅ ADDED: Import HapticUtils

/// Forgot Password View
/// Mirrors Swift ForgotPasswordSheet for password reset UI
class ForgotPasswordView extends StatefulWidget {
  final VoidCallback? onClose;

  const ForgotPasswordView({
    Key? key,
    this.onClose,
  }) : super(key: key);

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final ForgotPasswordService _forgotPasswordService = ForgotPasswordService.shared;
  late ForgotPasswordModel _forgotPasswordModel;
  bool _isSending = false;
  
  // Controllers for password fields
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _forgotPasswordModel = ForgotPasswordModel();
  }

  @override
  void dispose() {
    _forgotPasswordModel.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
      value: _forgotPasswordModel,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.primaryDark),
            onPressed: () {
              _forgotPasswordModel.resetForgotPasswordState();
              if (widget.onClose != null) {
                widget.onClose!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(
              color: AppTheme.primaryDark,
              fontFamily: AppTheme.fontPoppins,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Step content
                Consumer<ForgotPasswordModel>(
                  builder: (context, model, child) {
                    switch (model.forgotPasswordStep) {
                      case 1:
                        return _buildEmailStep();
                      case 2:
                        return _buildCodeStep();
                      case 3:
                        return _buildPasswordStep();
                      default:
                        return _buildEmailStep();
                    }
                  },
                ),
                
                const SizedBox(height: AppTheme.spacingXLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 1: Email Input
  Widget _buildEmailStep() {
    return Column(
      children: [
        Text(
          'Reset Your Password',
          style: AppTheme.headlineLarge.copyWith(
            fontSize: 22,
            color: AppTheme.primaryDark,
            fontFamily: AppTheme.fontPoppins,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        Text(
          'Enter your email address and we\'ll send you a 6-digit verification code.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
            fontFamily: AppTheme.fontPoppins,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // Email Field
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            return TextField(
              onChanged: (value) => model.forgotPasswordEmail = value,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Message
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            if (model.forgotPasswordMessage.isEmpty) {
              return const SizedBox();
            }
            
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: _getMessageColor(model.forgotPasswordMessage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: _getMessageColor(model.forgotPasswordMessage).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMessageColor(model.forgotPasswordMessage) == Colors.green
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _getMessageColor(model.forgotPasswordMessage),
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      model.forgotPasswordMessage,
                      style: AppTheme.bodySmall.copyWith(
                        color: _getMessageColor(model.forgotPasswordMessage),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // Send Code Button
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            return BravoButton(
              onPressed: model.forgotPasswordEmail.isEmpty || _isSending
                  ? null
                  : () async {
                      HapticUtils.lightImpact(); // ✅ ADDED: Light haptic feedback
                      setState(() => _isSending = true);
                      await _forgotPasswordService.sendForgotPassword(
                        model.forgotPasswordEmail,
                        model,
                      );
                      setState(() => _isSending = false);
                    },
              text: _isSending ? 'Sending...' : 'Send Verification Code',
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: Colors.white,
              disabled: model.forgotPasswordEmail.isEmpty || _isSending,
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
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            return Text(
              'We\'ve sent a 6-digit code to ${model.forgotPasswordEmail}',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.primaryGray,
                fontFamily: AppTheme.fontPoppins,
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // Code Field
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            return TextField(
              onChanged: (value) {
                // Limit to 6 digits
                if (value.length <= 6) {
                  model.forgotPasswordCode = value;
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                counterText: '', // Hide character counter
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Message
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            if (model.forgotPasswordMessage.isEmpty) {
              return const SizedBox();
            }
            
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: _getMessageColor(model.forgotPasswordMessage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: _getMessageColor(model.forgotPasswordMessage).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMessageColor(model.forgotPasswordMessage) == Colors.green
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _getMessageColor(model.forgotPasswordMessage),
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      model.forgotPasswordMessage,
                      style: AppTheme.bodySmall.copyWith(
                        color: _getMessageColor(model.forgotPasswordMessage),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // Verify Code Button
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            return BravoButton(
              onPressed: model.forgotPasswordCode.length != 6 || _isSending
                  ? null
                  : () async {
                      HapticUtils.lightImpact(); // ✅ ADDED: Light haptic feedback
                      setState(() => _isSending = true);
                      await _forgotPasswordService.verifyResetCode(
                        model.forgotPasswordCode,
                        model,
                      );
                      setState(() => _isSending = false);
                    },
              text: _isSending ? 'Verifying...' : 'Verify Code',
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: Colors.white,
              disabled: model.forgotPasswordCode.length != 6 || _isSending,
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Resend Code Button
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            return BravoButton(
              onPressed: _isSending
                  ? null
                  : () async {
                      HapticUtils.lightImpact(); // ✅ ADDED: Light haptic feedback
                      setState(() => _isSending = true);
                      await _forgotPasswordService.sendForgotPassword(
                        model.forgotPasswordEmail,
                        model,
                      );
                      setState(() => _isSending = false);
                    },
              text: 'Resend Code',
              color: Colors.white,
              backColor: AppTheme.lightGray,
              textColor: AppTheme.primaryYellow,
              disabled: _isSending,
              borderSide: BorderSide(color: AppTheme.lightGray, width: 2),
            );
          },
        ),
      ],
    );
  }

  // Step 3: New Password
  Widget _buildPasswordStep() {
    return Column(
      children: [
        Text(
          'Set New Password',
          style: AppTheme.headlineLarge.copyWith(
            fontSize: 22,
            color: AppTheme.primaryDark,
            fontFamily: AppTheme.fontPoppins,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        Text(
          'Enter your new password',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
            fontFamily: AppTheme.fontPoppins,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // New Password Field
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            // Update controller when model changes
            if (_newPasswordController.text != model.forgotPasswordNewPassword) {
              _newPasswordController.text = model.forgotPasswordNewPassword;
            }
            
            return TextField(
              controller: _newPasswordController,
              onChanged: (value) => model.forgotPasswordNewPassword = value,
              obscureText: !model.isNewPasswordVisible,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'Enter new password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => model.isNewPasswordVisible = !model.isNewPasswordVisible,
                  icon: Icon(
                    model.isNewPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppTheme.primaryYellow,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Confirm Password Field
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            // Update controller when model changes
            if (_confirmPasswordController.text != model.forgotPasswordConfirmPassword) {
              _confirmPasswordController.text = model.forgotPasswordConfirmPassword;
            }
            
            return TextField(
              controller: _confirmPasswordController,
              onChanged: (value) => model.forgotPasswordConfirmPassword = value,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                hintText: 'Confirm new password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: AppTheme.primaryYellow, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.lightGray.withOpacity(0.1),
                contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingMedium),
        
        // Message
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            if (model.forgotPasswordMessage.isEmpty) {
              return const SizedBox();
            }
            
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: _getMessageColor(model.forgotPasswordMessage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: _getMessageColor(model.forgotPasswordMessage).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMessageColor(model.forgotPasswordMessage) == Colors.green
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: _getMessageColor(model.forgotPasswordMessage),
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      model.forgotPasswordMessage,
                      style: AppTheme.bodySmall.copyWith(
                        color: _getMessageColor(model.forgotPasswordMessage),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingLarge),
        
        // Reset Password Button
        Consumer<ForgotPasswordModel>(
          builder: (context, model, child) {
            return BravoButton(
              onPressed: (model.forgotPasswordNewPassword.isEmpty ||
                         model.forgotPasswordConfirmPassword.isEmpty ||
                         _isSending)
                  ? null
                  : () async {
                      HapticUtils.lightImpact(); // ✅ ADDED: Light haptic feedback
                      setState(() => _isSending = true);
                      await _forgotPasswordService.resetPassword(
                        model.forgotPasswordNewPassword,
                        model.forgotPasswordConfirmPassword,
                        model,
                        onSuccess: () {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset successfully!'),
                              backgroundColor: AppTheme.success,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          // Navigate back to login page
                          if (widget.onClose != null) {
                            widget.onClose!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                      setState(() => _isSending = false);
                    },
              text: _isSending ? 'Resetting...' : 'Reset Password',
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: Colors.white,
              disabled: model.forgotPasswordNewPassword.isEmpty ||
                       model.forgotPasswordConfirmPassword.isEmpty ||
                       _isSending,
            );
          },
        ),
      ],
    );
  }
} 