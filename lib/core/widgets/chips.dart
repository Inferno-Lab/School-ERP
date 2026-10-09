import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SoftChip extends StatelessWidget {
  const SoftChip({
    required this.label,
    this.icon,
    this.tint,
    this.tone,
    this.onTap,
    this.selected = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? tint;
  final Color? tone;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final fg = tone ?? context.colors.primary;
    final bg = tint ?? context.colors.primary.withValues(alpha: 0.12);
    return Material(
      color: selected ? fg : bg,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? context.colors.onPrimary : fg),
                const SizedBox(width: 6),
              ],
              Text(
                label.tr,
                style: context.text.labelLarge?.copyWith(
                  color: selected ? context.colors.onPrimary : fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubjectChip extends StatelessWidget {
  const SubjectChip({required this.subject, super.key});

  final String subject;

  @override
  Widget build(BuildContext context) {
    final colors = context.app.subject(subject);
    return SoftChip(
      label: 'subject.$subject'.tr,
      tint: colors.tint,
      tone: colors.tone,
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    super.key,
  });

  factory StatusBadge.tone(
    {
    required String label,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return StatusBadge(
      label: label,
      icon: icon,
      color: color,
      background: background,
    );
  }

  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label.tr, style: context.text.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

StatusBadge attendanceBadge(BuildContext context, String status) {
  final app = context.app;
  return switch (status) {
    'present' => StatusBadge(
      label: 'status.present',
      icon: PhosphorIconsFill.checkCircle,
      color: app.success,
      background: app.successContainer,
    ),
    'absent' => StatusBadge(
      label: 'status.absent',
      icon: PhosphorIconsFill.xCircle,
      color: app.danger,
      background: app.dangerContainer,
    ),
    'late' || 'lateArrival' => StatusBadge(
      label: 'status.late',
      icon: PhosphorIconsFill.clock,
      color: app.warning,
      background: app.warningContainer,
    ),
    'holiday' => StatusBadge(
      label: 'status.holiday',
      icon: PhosphorIconsFill.sun,
      color: app.info,
      background: app.infoContainer,
    ),
    'paid' => StatusBadge(
      label: 'status.paid',
      icon: PhosphorIconsFill.checkCircle,
      color: app.success,
      background: app.successContainer,
    ),
    'due' => StatusBadge(
      label: 'status.due',
      icon: PhosphorIconsFill.hourglass,
      color: app.warning,
      background: app.warningContainer,
    ),
    'overdue' => StatusBadge(
      label: 'status.overdue',
      icon: PhosphorIconsFill.warningCircle,
      color: app.danger,
      background: app.dangerContainer,
    ),
    'pending' => StatusBadge(
      label: 'status.pending',
      icon: PhosphorIconsFill.hourglass,
      color: app.warning,
      background: app.warningContainer,
    ),
    'approved' => StatusBadge(
      label: 'status.approved',
      icon: PhosphorIconsFill.checkCircle,
      color: app.success,
      background: app.successContainer,
    ),
    'rejected' => StatusBadge(
      label: 'status.rejected',
      icon: PhosphorIconsFill.xCircle,
      color: app.danger,
      background: app.dangerContainer,
    ),
    'submitted' => StatusBadge(
      label: 'status.submitted',
      icon: PhosphorIconsFill.paperPlaneTilt,
      color: app.info,
      background: app.infoContainer,
    ),
    'graded' => StatusBadge(
      label: 'status.graded',
      icon: PhosphorIconsFill.star,
      color: app.success,
      background: app.successContainer,
    ),
    _ => StatusBadge(
      label: status,
      icon: PhosphorIconsRegular.circle,
      color: context.colors.onSurfaceVariant,
      background: context.colors.surfaceContainer,
    ),
  };
}

SubjectColor subjectColor(BuildContext context, String id) => context.app.subject(id);
