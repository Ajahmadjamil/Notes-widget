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

class UsernameSetupScreen extends StatelessWidget {
  const UsernameSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsernameSetupController(),
      child: Consumer<UsernameSetupController>(
        builder: (context, controller, _) {
          return PopScope(
            canPop: false,
            child: Stack(
            children: [
              SafeArea(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Scaffold(
                    backgroundColor: AppColors.bgColor,
                    body: Padding(
                      padding: const EdgeInsets.all(20),
                      child: FadeSlideIn(
                        child: AppContainer(
                          borderRadius: 32,
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 40,
                                color: AppColors.selectedColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Choose a username',
                                style: getSemiBoldStyle(
                                  fontSize: 22,
                                  color: AppColors.textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Usernames are unique and used when friends search for you.',
                                style: getRegularStyle(color: AppColors.textColor2),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Username',
                                style: getMediumStyle(fontSize: 13, color: AppColors.textColor),
                              ),
                              const SizedBox(height: 8),
                              InputField(
                                hint: 'e.g. jamil_notes',
                                controller: controller.usernameController,
                                focusNode: controller.usernameFocusNode,
                                textInputAction: TextInputAction.done,
                                prefixIcon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '3–20 characters: letters, numbers, underscore',
                                style: getRegularStyle(
                                  fontSize: 12,
                                  color: AppColors.textColor2,
                                ),
                              ),
                              const SizedBox(height: 28),
                              CustomButton(
                                onTap: () => controller.submit(context),
                                label: 'Continue',
                                color: AppColors.primaryColor,
                                widget: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (controller.isLoading)
                Container(
                  color: AppColors.selectedColor.withValues(alpha: 0.4),
                  child: const Center(child: CustomLoading()),
                ),
            ],
            ),
          );
        },
      ),
    );
  }
}
