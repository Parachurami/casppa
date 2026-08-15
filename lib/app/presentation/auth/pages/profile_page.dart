import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/utils/string_formatting.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/core/widgets/tag_pill.dart';
import 'package:casppa/app/domain/auth/params/update_profile_params.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  bool _isSaving = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).valueOrNull;
    _fullNameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await ref
        .read(authNotifierProvider.notifier)
        .updateProfile(
          UpdateProfileParams(fullName: _fullNameController.text.trim()),
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (_) => AppToast.success(context, 'Profile updated.'),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    await ref.read(authNotifierProvider.notifier).logout();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final initials = user == null ? '' : initialsFromName(user.name);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(height: 12),
                  Center(child: TagPill(label: user.role.name)),
                ],
                const SizedBox(height: 32),
                Text('Full name', style: AppTextStyles.title),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _fullNameController,
                  label: 'Full name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your full name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Email', style: AppTextStyles.title),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    user?.email ?? '',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save changes',
                  isLoading: _isSaving,
                  onPressed: _save,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.statusOverdueBackground,
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoggingOut ? null : _logout,
                    child: _isLoggingOut
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : const Text('Log out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
