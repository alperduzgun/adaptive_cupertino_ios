import 'package:flutter/cupertino.dart';

class BentoShowcasePage extends StatefulWidget {
  const BentoShowcasePage({super.key});

  @override
  State<BentoShowcasePage> createState() => _BentoShowcasePageState();
}

class _BentoShowcasePageState extends State<BentoShowcasePage> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _buildFeaturedCard(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            delegate: SliverChildListDelegate([
              _buildNativeCard('System Blur', 'Native Material',
                  CupertinoIcons.layers_fill, CupertinoColors.systemPurple),
              _buildNativeCard('Native UI', 'iOS 26 High-Fi',
                  CupertinoIcons.bolt_fill, CupertinoColors.systemYellow),
              _buildNativeCard(
                  'Adaptive',
                  'Swift Driven',
                  CupertinoIcons.square_grid_2x2_fill,
                  CupertinoColors.systemBlue),
              _buildNativeCard('Speed', '60 FPS Metal', CupertinoIcons.gauge,
                  CupertinoColors.systemGreen),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildFeaturedCard(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildNativeCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: CupertinoColors.white.withOpacity(0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: -0.4)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  color: CupertinoColors.secondaryLabel,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: CupertinoColors.label.withOpacity(0.05),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: CupertinoColors.white.withOpacity(0.1), width: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('The Future is Adaptive',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.7)),
          const SizedBox(height: 8),
          Text(
              'Experience the cutting-edge iOS 26 design system within Flutter.',
              style: TextStyle(
                  color: CupertinoColors.label.withOpacity(0.6),
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
