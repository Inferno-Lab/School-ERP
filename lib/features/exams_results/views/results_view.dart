import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/progress.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/features/exams_results/controllers/results_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResultsView extends GetView<ResultsController> {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final result = controller.result;
      final exam = controller.exam;
      return FeaturePage(
        title: 'results.title',
        subtitle: 'results.subtitle',
        onRefresh: controller.load,
        child: ViewStateView(
          state: controller.state.value,
          onRetry: controller.load,
          errorKey: controller.errorMessage.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.exams.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => ChoiceChip(
                      label: Text(controller.exams[index].name),
                      selected: controller.examIndex.value == index,
                      onSelected: (_) => controller.examIndex.value = index,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (result == null)
                  EmptyState(
                    title: 'results.empty',
                    body: exam == null
                        ? 'home.no_exam'
                        : 'time.days_left'.trParams({
                            'count': '${Formatters.daysUntil(exam.startDate)}',
                          }),
                  )
                else
                  _ResultBody(result: result),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.app.gradientStart, context.app.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('results.overall'.tr, style: context.text.bodyMedium?.copyWith(color: Colors.white)),
              AnimatedCounter(
                value: result.overallPercent,
                decimals: 1,
                suffix: '%',
                size: 36,
                color: Colors.white,
              ),
              Text(
                '${result.grade} · ${'results.rank'.trParams({'rank': '${result.rank}', 'total': '${result.totalStudents}'})}',
                style: context.text.titleMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('results.subjects'.tr, style: context.text.headlineSmall),
        for (final subject in result.subjects) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('subject.${subject.subject}'.tr, style: context.text.titleSmall)),
              Text('${subject.marks}/${subject.maxMarks}', style: context.text.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          AnimatedBar(
            value: subject.marks / subject.maxMarks,
            color: context.app.subject(subject.subject).tone,
          ),
        ],
        const SizedBox(height: 20),
        Text('results.trend'.tr, style: context.text.headlineSmall),
        const SizedBox(height: 8),
        SizedBox(height: 180, child: _Trend(result: result)),
        const SizedBox(height: 12),
        SizedBox(height: 220, child: _Radar(result: result)),
      ],
    );
  }
}

class _Trend extends StatelessWidget {
  const _Trend({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= result.trend.length) return const SizedBox.shrink();
                return Text(result.trend[index].label, style: context.text.bodySmall);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: context.colors.primary,
            barWidth: 3,
            spots: [
              for (var i = 0; i < result.trend.length; i++)
                FlSpot(i.toDouble(), result.trend[i].percent),
            ],
          ),
        ],
      ),
    );
  }
}

class _Radar extends StatelessWidget {
  const _Radar({required this.result});

  final ExamResult result;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            dataEntries: [
              for (final subject in result.subjects)
                RadarEntry(value: subject.marks / subject.maxMarks * 100),
            ],
            fillColor: color.withValues(alpha: 0.18),
            borderColor: color,
            entryRadius: 3,
          ),
        ],
        radarShape: RadarShape.polygon,
        tickCount: 3,
        ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
        gridBorderData: BorderSide(color: context.colors.outline),
        radarBorderData: BorderSide(color: context.colors.outline),
        titleTextStyle: context.text.bodySmall,
        getTitle: (index, angle) => RadarChartTitle(
          text: 'subject.${result.subjects[index].subject}'.tr,
        ),
      ),
    );
  }
}
