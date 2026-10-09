import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/validators.dart';
import 'package:edunest/core/widgets/app_text_field.dart';
import 'package:edunest/core/widgets/buttons.dart';
import 'package:edunest/core/widgets/misc.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/features/auth/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.app.gradientStart, context.app.gradientEnd],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NestMark(size: 64),
                      const SizedBox(height: 8),
                      Text(
                        'auth.welcome'.trParams({'app': AppConfig.appName}),
                        style: context.text.headlineMedium?.copyWith(color: Colors.white),
                      ),
                      Text(
                        'auth.subtitle'.tr,
                        style: context.text.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Text('auth.demo'.tr, style: context.text.headlineSmall),
                  const SizedBox(height: 12),
                  const _RoleCard(
                    title: 'nav.student',
                    body: 'auth.student_body',
                    icon: PhosphorIconsDuotone.student,
                    role: UserRole.student,
                  ),
                  const _RoleCard(
                    title: 'nav.parent',
                    body: 'auth.parent_body',
                    icon: PhosphorIconsDuotone.usersThree,
                    role: UserRole.parent,
                  ),
                  const _RoleCard(
                    title: 'nav.teacher',
                    body: 'auth.teacher_body',
                    icon: PhosphorIconsDuotone.chalkboardTeacher,
                    role: UserRole.teacher,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'auth.demo_hint'.tr,
                    style: context.text.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text('auth.or'.tr, style: context.text.titleMedium),
                  const SizedBox(height: 12),
                  Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          label: 'auth.email',
                          controller: controller.email,
                          validator: Validators.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (controller.useOtp.value) {
                            return OtpField(
                              controller: controller.otp,
                              validator: Validators.otp,
                            );
                          }
                          return AppTextField(
                            label: 'auth.password',
                            controller: controller.password,
                            validator: Validators.password,
                            obscure: true,
                          );
                        }),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => controller.useOtp.toggle(),
                      child: Obx(
                        () => Text(
                          (controller.useOtp.value
                                  ? 'auth.use_password'
                                  : 'auth.use_otp')
                              .tr,
                        ),
                      ),
                    ),
                  ),
                  Obx(
                    () => PrimaryButton(
                      label: 'auth.login',
                      loading: controller.loading.value,
                      onPressed: controller.submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends GetView<LoginController> {
  const _RoleCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.role,
  });

  final String title;
  final String body;
  final IconData icon;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Obx(
          () => InkWell(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            onTap: controller.loading.value ? null : () => controller.demo(role),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: context.colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.tr, style: context.text.titleMedium),
                        Text(body.tr, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    color: context.colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
