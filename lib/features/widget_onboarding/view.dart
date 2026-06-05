import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/shared/animations/app_animations.dart';
import 'package:noteswidgetapp/core/shared/widgets/app_container.dart';
import 'package:noteswidgetapp/core/shared/widgets/custom_button.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/theme/textfont_styles.dart';
import 'package:noteswidgetapp/core/widget/widget_setup_helper.dart';
import 'package:provider/provider.dart';

import '../../core/alerts/custom_loading.dart';
import 'controller.dart';

class WidgetOnboardingScreen extends StatefulWidget {
  const WidgetOnboardingScreen({super.key});

  @override
  State<WidgetOnboardingScreen> createState() => _WidgetOnboardingScreenState();
}

class _WidgetOnboardingScreenState extends State<WidgetOnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetSetupHelper.requestPinIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WidgetOnboardingController(),
      child: Consumer<WidgetOnboardingController>(
        builder: (context, controller, _) {
          return PopScope(
            canPop: false,
            child: Stack(
              children: [
                Scaffold(
                  backgroundColor: AppColors.bgColor,
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          FadeSlideIn(
                            child: AppContainer(
                              borderRadius: 32,
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: AppContainer(
                                      borderRadius: 24,
                                      padding: const EdgeInsets.all(20),
                                      child: Icon(
                                        Icons.widgets_outlined,
                                        size: 56,
                                        color: AppColors.selectedColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Add the home screen widget',
                                    style: getSemiBoldStyle(
                                      fontSize: 22,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Your shared note updates on the widget in real time — even when the app is closed (after you tap Add on the system dialog).',
                                    style: getRegularStyle(color: AppColors.textColor2),
                                  ),
                                  const SizedBox(height: 20),
                                  _Bullet(text: 'Tap the widget to open that shared note'),
                                  _Bullet(text: 'Updates when your friend edits'),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 200),
                            child: CustomButton(
                              onTap: controller.isLoading
                                  ? null
                                  : () => controller.addWidget(context),
                              label: 'Show add widget prompt',
                              color: AppColors.primaryColor,
                              widget: const Icon(
                                Icons.add_to_home_screen,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CustomButton(
                            onTap: controller.isLoading
                                ? null
                                : () => controller.skip(context),
                            label: 'Continue without widget',
                            color: AppColors.btnColorLight,
                            style: getMediumStyle(color: AppColors.textColor),
                          ),
                        ],
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

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: getRegularStyle(color: AppColors.primaryColor)),
          Expanded(
            child: Text(text, style: getRegularStyle(color: AppColors.textColor)),
          ),
        ],
      ),
    );
  }
}
