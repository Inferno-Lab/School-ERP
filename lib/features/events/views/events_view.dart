import 'package:cached_network_image/cached_network_image.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/app_card.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/features/events/controllers/events_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EventsView extends GetView<EventsController> {
  const EventsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FeaturePage(
        title: 'events.title',
        subtitle: 'events.subtitle',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              children: [
                for (final event in controller.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      onTap: () => Get.toNamed<void>('/events/${event.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppRadius.card),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: event.imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                height: 140,
                                color: context.colors.primary.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(event.title, style: context.text.titleMedium),
                                Text(
                                  '${Formatters.fullDate(event.date)} · ${event.time} · ${event.venue}',
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class EventDetailView extends GetView<EventsController> {
  const EventDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final event = controller.byId(Get.parameters['id']);
      final userId = Get.find<AuthService>().user.value?.id;
      RsvpStatus? mine;
      for (final rsvp in event?.rsvps ?? const <Rsvp>[]) {
        if (rsvp.userId == userId) mine = rsvp.status;
      }
      return FeaturePage(
        title: 'events.title',
        subtitle: event?.title ?? 'events.subtitle',
        child: event == null
            ? const EmptyState(title: 'empty.title', body: 'empty.body')
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.description, style: context.text.bodyLarge),
                    const SizedBox(height: 8),
                    Text('${event.venue} · ${event.time}', style: context.text.bodyMedium),
                    const SizedBox(height: 16),
                    Text('events.rsvp'.tr, style: context.text.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final status in RsvpStatus.values)
                          ChoiceChip(
                            label: Text('events.${status.name}'.tr),
                            selected: mine == status,
                            onSelected: (_) => controller.rsvp(event.id, status),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      );
    });
  }
}
