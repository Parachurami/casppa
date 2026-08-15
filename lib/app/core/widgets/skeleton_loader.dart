import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:casppa/app/core/theme/app_colors.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerGroup extends StatelessWidget {
  const ShimmerGroup({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: child,
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    required this.itemBuilder,
    this.itemCount = 4,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 24),
    this.separatorHeight = 16,
    super.key,
  });

  final Widget Function(BuildContext context, int index) itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final double separatorHeight;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.background,
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => SizedBox(height: separatorHeight),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class AssignmentCardSkeleton extends StatelessWidget {
  const AssignmentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SkeletonBox(width: 64, height: 22, borderRadius: 12),
              SizedBox(width: 8),
              SkeletonBox(width: 80, height: 22, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: 180, height: 16),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 12),
          const SizedBox(height: 6),
          const SkeletonBox(width: 220, height: 12),
          const SizedBox(height: 14),
          const SkeletonBox(width: 140, height: 12),
          const SizedBox(height: 16),
          const SkeletonBox(width: double.infinity, height: 44, borderRadius: 12),
        ],
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ShimmerGroup(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonBox(width: 120, height: 24),
                    SkeletonBox(width: 36, height: 36, borderRadius: 18),
                  ],
                ),
                const SizedBox(height: 24),
                const SkeletonBox(width: 200, height: 24),
                const SizedBox(height: 12),
                const SkeletonBox(width: 260, height: 14),
                const SizedBox(height: 20),
                const SkeletonBox(width: double.infinity, height: 40, borderRadius: 12),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) =>
                        const AssignmentCardSkeleton(),
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

class SubmissionTileSkeleton extends StatelessWidget {
  const SubmissionTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 120, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 12),
              ],
            ),
          ),
          const SkeletonBox(width: 64, height: 22, borderRadius: 12),
        ],
      ),
    );
  }
}
