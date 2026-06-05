import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/shared/widgets/input_field.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:provider/provider.dart';

import '../../../core/alerts/custom_loading.dart';
import 'controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Consumer<LoginController>(
        builder: (context, controller, _) {
          return Stack(
            children: [
              SafeArea(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Scaffold(
                    backgroundColor: AppColors.bgColor,
                    resizeToAvoidBottomInset: true,
                    body: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 48),
                                  FadeSlideIn(
                                    child: Column(
                                      children: [
                                        AppContainer(
                                          borderRadius: 20,
                                          padding: const EdgeInsets.all(16),
                                          child: Icon(
                                            Icons.notes_rounded,
                                            size: 36,
                                            color: AppColors.selectedColor,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'SyncNotes',
                                          style: getBoldStyle(
                                            fontSize: 28,
                                            color: AppColors.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'PORTAL ACCESS',
                                          style: getRegularStyle(
                                            fontSize: 11,
                                            color: AppColors.textColor2,
                                          ).copyWith(letterSpacing: 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 150),
                                    child: AppContainer(
                                      borderRadius: 36,
                                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            controller.isSignUpMode
                                                ? 'Create Account'
                                                : 'Welcome Back',
                                            style: getSemiBoldStyle(
                                              fontSize: 22,
                                              color: AppColors.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            controller.isSignUpMode
                                                ? 'Set up your sync identity'
                                                : 'Sign in to continue',
                                            style: getRegularStyle(
                                              fontSize: 13,
                                              color: AppColors.textColor2,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'Email',
                                            style: getMediumStyle(
                                              fontSize: 13,
                                              color: AppColors.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InputField(
                                            hint: 'Enter Email Address',
                                            controller: controller.emailController,
                                            focusNode: controller.emailFocusNode,
                                            nextFocusNode: controller.passwordFocusNode,
                                            textInputAction: TextInputAction.next,
                                            prefixIcon: Icons.alternate_email_rounded,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Password',
                                            style: getMediumStyle(
                                              fontSize: 13,
                                              color: AppColors.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InputField(
                                            hint: 'Enter Password',
                                            controller: controller.passwordController,
                                            isPassword: true,
                                            focusNode: controller.passwordFocusNode,
                                            textInputAction: TextInputAction.done,
                                            prefixIcon: Icons.lock_outline_rounded,
                                          ),
                                          const SizedBox(height: 24),
                                          CustomButton(
                                            onTap: () => controller.submitEmailPassword(context),
                                            label: controller.isSignUpMode ? 'Sign Up' : 'Initialize Sync',
                                            color: AppColors.primaryColor,
                                            widget: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(child: Divider(color: AppColors.borderColor)),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                child: Text(
                                                  'OR',
                                                  style: getRegularStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textColor2,
                                                  ).copyWith(letterSpacing: 1.5),
                                                ),
                                              ),
                                              Expanded(child: Divider(color: AppColors.borderColor)),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          CustomButton(
                                            onTap: () => controller.signInWithGoogle(context),
                                            label: 'Continue with Google',
                                            color: AppColors.btnColorLight,
                                            style: getMediumStyle(
                                              fontSize: 14,
                                              color: AppColors.textColor,
                                            ),
                                            widget: const Icon(
                                              Icons.g_mobiledata,
                                              size: 24,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 300),
                                    child: TextButton(
                                      onPressed: controller.toggleSignUpMode,
                                      child: Text(
                                        controller.isSignUpMode
                                            ? 'Already have an account? Log in'
                                            : 'New here? Create an account',
                                        style: getRegularStyle(color: AppColors.primaryColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Version 1.0.0',
                                    style: getRegularStyle(
                                      fontSize: 12,
                                      color: AppColors.textColor2,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (controller.isLoading)
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: AppColors.selectedColor.withValues(alpha: 0.4),
                  child: const Center(child: CustomLoading()),
                ),
            ],
          );
        },
      ),
    );
  }
}
