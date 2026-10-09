import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/app_avatar.dart';
import 'package:edunest/core/widgets/app_card.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/student.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileController extends GetxController with Loadable {
  Student? student;
  SchoolClass? schoolClass;

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) {
      await run(() async {}, isEmpty: () => false);
      return;
    }
    await run(() async {
      final directory = Get.find<DirectoryRepository>();
      student = await directory.student(id);
      schoolClass = await directory.schoolClass(student!.classId);
    }, isEmpty: () => false);
  }

  Future<void> editPhoto() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      await Get.find<AuthService>().updateAvatar(file.path);
      ToastHelper.show('profile.photo', kind: ToastKind.success);
    } on Exception {
      ToastHelper.show('profile.photo');
    }
  }
}

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return Obx(() {
      final user = auth.user.value;
      return FeaturePage(
        title: 'profile.title',
        subtitle: user?.email ?? '',
        onRefresh: controller.load,
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            GradientHeader(
              height: 180,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: GestureDetector(
                  onTap: controller.editPhoto,
                  child: Stack(
                    children: [
                      AppAvatar(
                        name: user?.name ?? '',
                        url: user?.avatarUrl,
                        size: 72,
                      ),
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(PhosphorIconsFill.camera, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? '', style: context.text.headlineMedium),
            if (controller.student != null)
              AppCard(
                child: Column(
                  children: [
                    _Row('profile.class', controller.schoolClass?.label ?? ''),
                    _Row('profile.roll', controller.student!.rollNo),
                    _Row('profile.house', controller.student!.house),
                    _Row('profile.blood', controller.student!.bloodGroup),
                    _Row('profile.guardian', controller.student!.guardianName),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text('profile.more'.tr, style: context.text.headlineSmall),
            for (final item in _links(user?.role))
              ListTile(
                leading: Icon(item.$1),
                title: Text(item.$2.tr),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () => Get.toNamed<void>(item.$3),
              ),
          ],
        ),
      );
    });
  }

  List<(IconData, String, String)> _links(UserRole? role) {
    final common = <(IconData, String, String)>[
      (PhosphorIconsRegular.megaphone, 'menu.notices', AppRoutes.notices),
      (PhosphorIconsRegular.calendar, 'menu.events', AppRoutes.events),
      (PhosphorIconsRegular.bell, 'menu.notifications', AppRoutes.notifications),
      (PhosphorIconsRegular.gear, 'menu.settings', AppRoutes.settings),
      (PhosphorIconsRegular.building, 'menu.about', AppRoutes.about),
      (PhosphorIconsRegular.question, 'menu.help', AppRoutes.help),
    ];
    if (role == UserRole.teacher) return common;
    return [
      (PhosphorIconsRegular.bus, 'menu.transport', AppRoutes.transport),
      (PhosphorIconsRegular.bookOpen, 'menu.library', AppRoutes.library),
      (PhosphorIconsRegular.image, 'menu.gallery', AppRoutes.gallery),
      (PhosphorIconsRegular.calendarCheck, 'menu.leave', AppRoutes.leave),
      ...common,
    ];
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label.tr, style: context.text.bodySmall)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  late Future<SchoolInfo> _school = Get.find<DirectoryRepository>().school();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _school,
      builder: (context, snapshot) {
        final school = snapshot.data;
        final failed = snapshot.hasError;
        return FeaturePage(
          title: 'about.title',
          subtitle: school?.tagline ?? AppConfig.appName,
          onRefresh: () async {
            setState(() {
              _school = Get.find<DirectoryRepository>().school();
            });
            await _school;
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: school == null
                ? failed
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('errors.generic'.tr, style: context.text.bodyLarge),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _school = Get.find<DirectoryRepository>().school();
                              });
                            },
                            child: Text('common.retry'.tr),
                          ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(school.name, style: context.text.headlineMedium),
                      const SizedBox(height: 8),
                      Text(school.about, style: context.text.bodyLarge),
                      const SizedBox(height: 12),
                      Text(school.address, style: context.text.bodyMedium),
                      Text(school.officeHours, style: context.text.bodySmall),
                      Text('${school.principal} · ${school.founded}', style: context.text.bodySmall),
                      Text(school.email, style: context.text.bodyMedium),
                      Text(school.phone, style: context.text.bodyMedium),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
