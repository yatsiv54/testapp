import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

enum ShimmerType { home, list, detail, settings, analytics }

class LoadingShimmerWidget extends StatelessWidget {
  final ShimmerType type;
  const LoadingShimmerWidget({super.key, this.type = ShimmerType.home});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8EDF5);
    final highlightColor = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF5F8FC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    Widget buildBox(double height, [double? width, double borderRadius = 16]) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      );
    }

    Widget content;

    switch (type) {
      case ShimmerType.home:
        content = ListView(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            buildBox(120),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: buildBox(72)),
                const SizedBox(width: 12),
                Expanded(child: buildBox(72)),
                const SizedBox(width: 12),
                Expanded(child: buildBox(72)),
              ],
            ),
            const SizedBox(height: 24),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: buildBox(80),
            )),
          ],
        );
        break;
      case ShimmerType.list:
        content = ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 8,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: buildBox(80),
          ),
        );
        break;
      case ShimmerType.detail:
        content = ListView(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            buildBox(200, double.infinity, 24),
            const SizedBox(height: 24),
            buildBox(40),
            const SizedBox(height: 16),
            buildBox(100),
            const SizedBox(height: 16),
            buildBox(60),
          ],
        );
        break;
      case ShimmerType.settings:
        content = ListView(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            buildBox(30, 150),
            const SizedBox(height: 16),
            buildBox(60),
            const SizedBox(height: 12),
            buildBox(60),
            const SizedBox(height: 32),
            buildBox(30, 150),
            const SizedBox(height: 16),
            buildBox(60),
          ],
        );
        break;
      case ShimmerType.analytics:
        content = ListView(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            buildBox(150),
            const SizedBox(height: 24),
            buildBox(250),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: buildBox(100)),
                const SizedBox(width: 16),
                Expanded(child: buildBox(100)),
              ],
            )
          ],
        );
        break;
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: content,
    );
  }
}
