import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MilestoneStep {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const MilestoneStep({
    required this.title,
    this.subtitle,
    this.icon,
  });
}

class MilestoneStepper extends StatelessWidget {
  final List<MilestoneStep> steps;
  final int currentStepIndex; // 0-based index

  const MilestoneStepper({
    super.key,
    required this.steps,
    required this.currentStepIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepBefore = index ~/ 2;
                final isPassed = stepBefore < currentStepIndex;
                return Expanded(
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? AppColors.primary
                          : AppColors.slate200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStepIndex;
              final isCurrent = stepIndex == currentStepIndex;

              return Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.primary
                      : isCurrent
                          ? AppColors.primary
                          : Colors.white,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.slate300,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.slate500,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isCurrent = index == currentStepIndex;
              final isCompleted = index < currentStepIndex;

              return Expanded(
                child: Text(
                  step.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isCurrent || isCompleted
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.primary
                        : isCompleted
                            ? AppColors.slate800
                            : AppColors.slate400,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
