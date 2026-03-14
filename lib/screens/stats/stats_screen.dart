import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Создано контента', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('0', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark)),
                    ],
                  ),
                ),
              ),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Генераций использовано', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('0', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark)),
                    ],
                  ),
                ),
              ),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Лайки', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('0', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark)),
                    ],
                  ),
                ),
              ),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ER %', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('—', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Графики (fl_chart)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Данные из content_stats', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
