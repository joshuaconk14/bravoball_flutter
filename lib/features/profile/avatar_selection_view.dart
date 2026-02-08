import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../services/user_manager_service.dart';
import '../../utils/avatar_helper.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/bravo_button.dart'; // ✅ ADDED: Import reusable BravoButton

class AvatarSelectionView extends StatefulWidget {
  const AvatarSelectionView({Key? key}) : super(key: key);

  @override
  State<AvatarSelectionView> createState() => _AvatarSelectionViewState();
}

class _AvatarSelectionViewState extends State<AvatarSelectionView> {
  String? _selectedAvatar;
  Color? _selectedBackgroundColor;

  @override
  void initState() {
    super.initState();
    // Load current avatar and background selection
    final userManager = Provider.of<UserManagerService>(context, listen: false);
    _selectedAvatar = userManager.selectedAvatar ?? AvatarHelper.getDefaultAvatar();
    _selectedBackgroundColor = userManager.avatarBackgroundColor ?? 
        AvatarHelper.getDefaultBackgroundColor();
  }

  Future<void> _saveAvatar() async {
    if (_selectedAvatar == null || _selectedBackgroundColor == null) return;

    HapticUtils.mediumImpact();
    
    try {
      final userManager = Provider.of<UserManagerService>(context, listen: false);
      await userManager.updateAvatarAndBackground(
        avatarPath: _selectedAvatar!,
        backgroundColor: _selectedBackgroundColor!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Avatar updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: ${e.toString()}'),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryDark),
          onPressed: () {
            HapticUtils.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Select Avatar',
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                
                // Current selection preview
                Builder(
                  builder: (context) {
                    final currentAvatar = _selectedAvatar ?? 
                        AvatarHelper.getDefaultAvatar();
                    final currentBgColor = _selectedBackgroundColor ?? 
                        AvatarHelper.getDefaultBackgroundColor();
                    
                    return Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentBgColor,
                            border: Border.all(
                              color: AppTheme.primaryYellow,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              currentAvatar,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: currentBgColor,
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selected Avatar',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Section title: Avatars
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Avatar',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Avatar grid
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: AvatarHelper.avatarCount,
                    itemBuilder: (context, index) {
                      final avatarPath = AvatarHelper.getAvatarPath(index);
                      final isSelected = _selectedAvatar == avatarPath;
                      
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () {
                            HapticUtils.lightImpact();
                            setState(() {
                              _selectedAvatar = avatarPath;
                            });
                          },
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryYellow 
                                    : Colors.grey.shade300,
                                width: isSelected ? 4 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                avatarPath ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppTheme.secondaryBlue,
                                    child: Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Section title: Background Colors
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Background Color',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Background color grid
                SizedBox(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: AvatarHelper.availableBackgroundColors.length,
                      itemBuilder: (context, index) {
                        final color = AvatarHelper.getBackgroundColor(index);
                        final isSelected = _selectedBackgroundColor?.value == color?.value;
                        
                        return GestureDetector(
                          onTap: () {
                            HapticUtils.lightImpact();
                            setState(() {
                              _selectedBackgroundColor = color;
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryYellow 
                                    : Colors.grey.shade300,
                                width: isSelected ? 4 : 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 24,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BravoButton(
                    text: 'Save Avatar',
                    onPressed: _saveAvatar,
                    color: AppTheme.primaryYellow,
                    backColor: AppTheme.primaryDarkYellow,
                    textColor: Colors.white,
                    disabled: _selectedAvatar == null || _selectedBackgroundColor == null,
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
