import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casppa/app/core/theme/app_colors.dart';
import 'package:casppa/app/core/theme/app_text_styles.dart';
import 'package:casppa/app/core/widgets/app_text_field.dart';
import 'package:casppa/app/core/widgets/app_toast.dart';
import 'package:casppa/app/core/widgets/primary_button.dart';
import 'package:casppa/app/domain/assignments/entities/class_option_entity.dart';
import 'package:casppa/app/domain/auth/entities/user_entity.dart';
import 'package:casppa/app/domain/auth/params/auth_sign_up_params.dart';
import 'package:casppa/app/presentation/assignments/provider/assignments_provider.dart';
import 'package:casppa/app/presentation/auth/provider/auth_provider.dart';
import 'package:casppa/app/presentation/auth/widgets/role_selector.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole? _selectedRole;
  ClassOptionEntity? _selectedClass;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null) {
      AppToast.error(context, 'Select your role.');
      return;
    }

    if (_selectedRole == UserRole.student && _selectedClass == null) {
      AppToast.error(context, 'Select your class.');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await ref
        .read(authNotifierProvider.notifier)
        .signUp(
          AuthSignUpParams(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            role: _selectedRole!,
            classId: _selectedRole == UserRole.student
                ? _selectedClass!.id
                : null,
          ),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (user) {
        final message = user == null
            ? "Account created — check your email to confirm it, then log in."
            : 'Account created!';

        AppToast.success(context, message);
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create your account', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text(
                  'Set up your Casppa account to get started.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _fullNameController,
                  label: 'Full name',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your full name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your email.';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Use at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text('I am a...', style: AppTextStyles.title),
                const SizedBox(height: 12),
                RoleSelector(
                  selectedRole: _selectedRole,
                  onChanged: (role) => setState(() {
                    _selectedRole = role;
                    if (role != UserRole.student) _selectedClass = null;
                  }),
                ),
                if (_selectedRole == UserRole.student) ...[
                  const SizedBox(height: 24),
                  Text('Class', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  _buildClassDropdown(),
                ],
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Sign up',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    final classOptions = ref.watch(allClassOptionsProvider);

    return classOptions.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => const Text('Could not load classes.'),
      data: (options) {
        if (options.isEmpty) {
          return Text(
            'No classes yet.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          );
        }

        return DropdownButtonFormField<ClassOptionEntity>(
          initialValue: _selectedClass,
          isExpanded: true,
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(option.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedClass = value),
        );
      },
    );
  }
}
