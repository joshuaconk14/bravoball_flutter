import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/user_manager_service.dart';
import '../../services/email_verification_service.dart';
import '../../models/email_verification_model.dart';
import '../../services/username_verification_service.dart';
import '../../models/username_verification_model.dart';
import '../../widgets/bravo_button.dart';
import '../../utils/haptic_utils.dart';

class EditDetailsView extends StatefulWidget {
  const EditDetailsView({Key? key}) : super(key: key);

  @override
  State<EditDetailsView> createState() => _EditDetailsViewState();
}

class _EditDetailsViewState extends State<EditDetailsView> {
  final EmailVerificationService _emailVerificationService = EmailVerificationService.shared;
  final UsernameVerificationService _usernameVerificationService = UsernameVerificationService.shared;
  late EmailVerificationModel _emailVerificationModel;
  late UsernameVerificationModel _usernameVerificationModel;
  bool _isSendingEmail = false;
  bool _isSendingUsername = false;

  @override
  void initState() {
    super.initState();
    _emailVerificationModel = EmailVerificationModel();
    _usernameVerificationModel = UsernameVerificationModel();

    final userManager = Provider.of<UserManagerService>(context, listen: false);
    _emailVerificationModel.newEmail = userManager.email;
    _usernameVerificationModel.newUsername = userManager.username;
  }

  @override
  void dispose() {
    _emailVerificationModel.dispose();
    _usernameVerificationModel.dispose();
    super.dispose();
  }

  Color _getMessageColor(String message) {
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('sent') ||
        lowerMessage.contains('verified') ||
        lowerMessage.contains('successfully')) {
      return Colors.green;
    }
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _emailVerificationModel),
        ChangeNotifierProvider.value(value: _usernameVerificationModel),
      ],
      child: Scaffold(
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
            'Edit Details',
            style: AppTheme.titleLarge,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ----- EMAIL SECTION -----
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildEmailStep(),
                ),

                const SizedBox(height: 20), // spacing between email & username sections

                // ----- USERNAME SECTION -----
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildUsernameStep(),
                ),

                const SizedBox(height: 20),
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
                  borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
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

        // Send Verification Code Button
        Consumer<EmailVerificationModel>(
          builder: (context, model, child) {
            return BravoButton(
              onPressed: model.newEmail.isEmpty || _isSendingEmail
                  ? null
                  : () async {
                      HapticUtils.lightImpact(); // ✅ ADDED: Light haptic feedback
                      setState(() => _isSendingEmail = true);
                      await _emailVerificationService.sendEmailVerification(
                        model.newEmail,
                        model,
                      );
                      setState(() => _isSendingEmail = false);
                    },
              text: _isSendingEmail ? 'Sending...' : 'Send Verification Code',
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: Colors.white,
              disabled: model.newEmail.isEmpty || _isSendingEmail,
            );
          },
        ),
      ],
    );
  }

  // Step 1: Current Username Display and New Username Input
  Widget _buildUsernameStep() {
    final userManager = Provider.of<UserManagerService>(context, listen: false);

    return Column(
      children: [
        // Header
        Text(
          'Update Your Username',
          style: AppTheme.headlineLarge.copyWith(
            fontSize: 22,
            color: AppTheme.primaryDark,
            fontFamily: AppTheme.fontPoppins,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Current username
        Text(
          'Current username: ${userManager.username.isNotEmpty ? userManager.username : 'Guest User'}',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
            fontFamily: AppTheme.fontPoppins,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Description
        Text(
          'Enter your new username. Changes will reflect after saving.',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.primaryGray,
            fontFamily: AppTheme.fontPoppins,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // New Username Field
        TextField(
          onChanged: (value) => _usernameVerificationModel.newUsername = value, // your model variable
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: InputDecoration(
            labelText: 'New Username',
            hintText: 'Enter your new username',
            prefixIcon: const Icon(Icons.person_outline),
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
              borderSide: const BorderSide(color: AppTheme.primaryYellow, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.lightGray.withOpacity(0.1),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),

        const SizedBox(height: 16),

        // Message
        Consumer<UsernameVerificationModel>(
          builder: (context, model, child) {
            if (model.usernameVerificationMessage.isEmpty) return const SizedBox();

            final color = _getMessageColor(model.usernameVerificationMessage);

            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    color == Colors.green ? Icons.check_circle_outline : Icons.error_outline,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.usernameVerificationMessage,
                      style: AppTheme.bodySmall.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        // Update Username Button
        Consumer<UsernameVerificationModel>(
          builder: (context, model, child) {
            return BravoButton(
              onPressed: model.newUsername.isEmpty || _isSendingUsername
                  ? null
                  : () async {
                      HapticUtils.lightImpact();
                      setState(() => _isSendingUsername = true);

                      final userManager =
                          Provider.of<UserManagerService>(context, listen: false);

                      try {
                        final success = await _usernameVerificationService.updateUsername(
                          model.newUsername,
                          userManager, // ✅ pass correct type
                        );

                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Username updated successfully!'),
                              backgroundColor: AppTheme.success,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppTheme.error,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSendingUsername = false);
                      }
                    },
              text: _isSendingUsername ? 'Updating...' : 'Update Username',
              color: AppTheme.primaryYellow,
              backColor: AppTheme.primaryDarkYellow,
              textColor: Colors.white,
              disabled: model.newUsername.isEmpty || _isSendingUsername,
            );
          },
        ),
      ],
    );
  }
}
