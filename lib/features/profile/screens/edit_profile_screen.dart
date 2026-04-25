import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../widgets/cge_avatar.dart';
import '../../../widgets/cge_input.dart';
import '../../../widgets/cge_button.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();
  final _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _gamertagController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _favouriteGameController;

  String? _avatarUrl;
  File? _pickedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _gamertagController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _favouriteGameController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _authRepo.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _nameController.text = profile.fullName;
          _gamertagController.text = profile.gamertag ?? '';
          _phoneController.text = profile.phone ?? '';
          _bioController.text = profile.bio ?? '';
          _favouriteGameController.text = profile.favouriteGame ?? '';
          _avatarUrl = profile.avatarUrl;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Upload avatar if picked
      String? newAvatarUrl;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final fileName =
            'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
        newAvatarUrl = await _authRepo.uploadAvatar(fileName, bytes);
      }

      await _authRepo.updateProfile(
        fullName: _nameController.text.trim(),
        gamertag: _gamertagController.text.trim().isNotEmpty
            ? _gamertagController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        favouriteGame: _favouriteGameController.text.trim().isNotEmpty
            ? _favouriteGameController.text.trim()
            : null,
        avatarUrl: newAvatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gamertagController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _favouriteGameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CgeButton(
              label: 'Save',
              size: CgeButtonSize.sm,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cyan),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Avatar section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          if (_pickedImage != null)
                            ClipOval(
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: Image.file(
                                  _pickedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            CgeAvatar(
                              imageUrl: _avatarUrl,
                              name: _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : 'User',
                              size: 100,
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cyan,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.base,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                size: 16,
                                color: AppColors.base,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to change photo',
                      style: AppTypography.bodySmall,
                    ),

                    const SizedBox(height: 32),

                    // Form fields
                    CgeInput(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _nameController,
                      prefixIcon: LucideIcons.user,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    CgeInput(
                      label: 'Gamertag',
                      hint: 'Enter your gamertag',
                      controller: _gamertagController,
                      prefixIcon: LucideIcons.gamepad2,
                    ),
                    const SizedBox(height: 20),

                    CgeInput(
                      label: 'Phone',
                      hint: 'Enter your phone number',
                      controller: _phoneController,
                      prefixIcon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    CgeInput(
                      label: 'Bio',
                      hint: 'Tell us about yourself...',
                      controller: _bioController,
                      prefixIcon: LucideIcons.alignLeft,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    CgeInput(
                      label: 'Favourite Game',
                      hint: 'e.g. FC 25, Call of Duty',
                      controller: _favouriteGameController,
                      prefixIcon: LucideIcons.gamepad2,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
