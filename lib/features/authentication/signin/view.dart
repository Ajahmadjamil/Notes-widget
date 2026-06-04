import 'package:flutter/material.dart';
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
                    body: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const SizedBox(height: 80),
                                  Container(
                                    width: double.infinity,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(32),
                                        topRight: Radius.circular(32),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                                      child: Column(
                                        children: [
                                          Text(
                                            controller.isSignUpMode
                                                ? 'Create Account'
                                                : 'Login Account',
                                            style: getSemiBoldStyle(
                                              fontSize: 20,
                                              color: AppColors.textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Email',
                                              style: getRegularStyle(color: AppColors.textColor),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InputField(
                                            hint: 'Enter Email Address',
                                            controller: controller.emailController,
                                            focusNode: controller.emailFocusNode,
                                            nextFocusNode: controller.passwordFocusNode,
                                            textInputAction: TextInputAction.next,
                                          ),
                                          const SizedBox(height: 16),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Password',
                                              style: getRegularStyle(color: AppColors.textColor),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          InputField(
                                            hint: 'Enter Password',
                                            controller: controller.passwordController,
                                            isPassword: true,
                                            focusNode: controller.passwordFocusNode,
                                            textInputAction: TextInputAction.done,
                                          ),
                                          const SizedBox(height: 20),
                                          CustomButton(
                                            onTap: () => controller.submitEmailPassword(context),
                                            label: controller.isSignUpMode ? 'Sign Up' : 'Login',
                                            color: AppColors.primaryColor,
                                            widget: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          CustomButton(
                                            onTap: () => controller.signInWithGoogle(context),
                                            label: 'Continue with Google',
                                            color: Colors.white,
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
                                          const SizedBox(height: 12),
                                          TextButton(
                                            onPressed: controller.toggleSignUpMode,
                                            child: Text(
                                              controller.isSignUpMode
                                                  ? 'Already have an account? Log in'
                                                  : 'New here? Create an account',
                                              style: getRegularStyle(color: AppColors.primaryColor),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Version 1.0.0',
                                            style: getRegularStyle(color: AppColors.textColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(child: CustomLoading()),
                ),
            ],
          );
        },
      ),
    );
  }
}
