import 'dart:math' as math;

import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter/cupertino.dart';

enum ShowcaseFeature {
  none,
  lensing,
  variants,
  morphing,
  controls,
  sheets,
  menus
}

class IOS26ShowcasePage extends StatefulWidget {
  const IOS26ShowcasePage({super.key});

  @override
  State<IOS26ShowcasePage> createState() => _IOS26ShowcasePageState();
}

class _IOS26ShowcasePageState extends State<IOS26ShowcasePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We REMOVE the AdaptiveScaffold here because main.dart already provides one.
    // This resolves the AppBar conflict.
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: _buildAnimatedBackground(),
          ),
        ),
        _buildMenu(),
      ],
    );
  }

  Widget _buildMenu() {
    return CustomScrollView(
      slivers: [
        // Match the HomePage large title height
        const SliverToBoxAdapter(child: SizedBox(height: 140)),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildMenuCard(
                'Lensing & Refraction',
                'Real-time light bending simulation behind the navigation layer.',
                CupertinoIcons.wind,
                ShowcaseFeature.lensing,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                'Button Styles',
                'Explore .glass, .prominent and .clear native button configs.',
                CupertinoIcons.layers,
                ShowcaseFeature.variants,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                'Liquid Morphing',
                'Fluid transformations between interactive control states.',
                CupertinoIcons.infinite,
                ShowcaseFeature.morphing,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                'Glass Controls',
                'High-fidelity Sliders, Switches, and Segmented Controls with real-time refraction.',
                CupertinoIcons.slider_horizontal_3,
                ShowcaseFeature.controls,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                'Immersive Sheets',
                'Native detached card-style presentation with material blending.',
                CupertinoIcons.square_stack_3d_up,
                ShowcaseFeature.sheets,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                'Menus & Dialogs',
                'Native context menus and alerts with Liquid Glass materials.',
                CupertinoIcons.conversation_bubble,
                ShowcaseFeature.menus,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
      String title, String subtitle, IconData icon, ShowcaseFeature feature) {
    return GestureDetector(
      onTap: () {
        // Navigate to dedicated page for true iOS back button behavior
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => _ShowcaseDetailPage(feature: feature),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CupertinoColors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: CupertinoColors.activeBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context))),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return CustomPaint(painter: _BackgroundPainter(_bgController.value));
      },
    );
  }
}

class _ShowcaseDetailPage extends StatefulWidget {
  final ShowcaseFeature feature;
  const _ShowcaseDetailPage({required this.feature});

  @override
  State<_ShowcaseDetailPage> createState() => _ShowcaseDetailPageState();
}

class _ShowcaseDetailPageState extends State<_ShowcaseDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  bool _isMorphed = false;
  bool _showBackground = true;
  bool _switchValue = true;
  double _sliderValue = 0.7;
  int _segmentedValue = 1;

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 60))
          ..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      extendBodyBehindAppBar: true,
      appBar: AdaptiveCupertinoAppBar(
        title: Text(_getFeatureTitle(widget.feature)),
        // The back button is handled automatically by Navigator + AdaptiveScaffold
      ),
      body: Stack(
        children: [
          if (_showBackground)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _bgController,
                  builder: (context, child) => CustomPaint(
                      painter: _BackgroundPainter(_bgController.value)),
                ),
              ),
            ),
          _buildActiveContent(),
        ],
      ),
    );
  }

  String _getFeatureTitle(ShowcaseFeature feature) {
    switch (feature) {
      case ShowcaseFeature.lensing:
        return 'Lensing';
      case ShowcaseFeature.variants:
        return 'Button Styles';
      case ShowcaseFeature.morphing:
        return 'Morphing';
      case ShowcaseFeature.controls:
        return 'Controls';
      case ShowcaseFeature.sheets:
        return 'Sheets';
      case ShowcaseFeature.menus:
        return 'Menus & Dialogs';
      default:
        return 'Detail';
    }
  }

  Widget _buildActiveContent() {
    switch (widget.feature) {
      case ShowcaseFeature.lensing:
        return _buildLensingDemo();
      case ShowcaseFeature.variants:
        return _buildVariantsDemo();
      case ShowcaseFeature.morphing:
        return _buildMorphingDemo();
      case ShowcaseFeature.controls:
        return _buildControlsDemo();
      case ShowcaseFeature.sheets:
        return _buildSheetsDemo();
      case ShowcaseFeature.menus:
        return _buildMenusDemo();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }

  Widget _buildLensingDemo() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoSection(
                  'Lensing Mechanics',
                  'In iOS 26, glass doesn\'t just blur; it refracts light relative to your viewing angle. Watch the background blobs curve behind the navigation layer.',
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Show Background'),
                    const SizedBox(width: 12),
                    CupertinoSwitch(
                      value: _showBackground,
                      onChanged: (v) => setState(() => _showBackground = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsDemo() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildVariantsSection(),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Native Button Configurations'),
        const SizedBox(height: 12),
        const Text(
          'In iOS 26, UIButton.Configuration adds high-fidelity glass variants. Each style represents a different material density and lensing behavior.',
          style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
        ),
        const SizedBox(height: 24),
        _buildButtonVariant(
          'Glass (.glass)',
          AdaptiveButtonStyle.glass,
          'The standard adaptive material. Balanced refraction and milkiness.',
        ),
        const SizedBox(height: 20),
        _buildButtonVariant(
          'Prominent (.prominentGlass)',
          AdaptiveButtonStyle.glassProminent,
          'Higher material density. Designed for primary actions.',
        ),
        const SizedBox(height: 20),
        _buildButtonVariant(
          'Clear (.clearGlass)',
          AdaptiveButtonStyle.glassClear,
          'Zero milkiness. High transparency. Best for visually rich backgrounds.',
        ),
        const SizedBox(height: 20),
        _buildButtonVariant(
          'Prominent Clear (.prominentClearGlass)',
          AdaptiveButtonStyle.glassIdentity, // Mapped to this on native side
          'Maximum lensing (distortion) without the white tint wash.',
        ),
        const SizedBox(height: 20),
        _buildButtonVariant(
          'Tinted Glass',
          AdaptiveButtonStyle.glassTinted,
          'A subtle 15% color wash infused into the glass material.',
          color: CupertinoColors.systemPurple,
        ),
      ],
    );
  }

  Widget _buildButtonVariant(
      String name, AdaptiveButtonStyle style, String desc,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CupertinoColors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              AdaptiveButton(
                style: style,
                color: color,
                onPressed: () => print('📱 Pressed: $name'),
                child: const Text('Action'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: CupertinoColors.secondaryLabel)),
        ],
      ),
    );
  }

  Widget _buildMorphingDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 140),
          _buildInfoSection(
            'Liquid Transformation',
            'Experience the gel-like morphing between two UI states. This uses bouncy physics inspired by Solarium design.',
          ),
          const SizedBox(height: 40),
          _buildMorphDemoUI(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildControlsDemo() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoSection(
                  'High-Fidelity Toggles',
                  'Native iOS 26 Switches now use the AdaptiveGlassView material, providing a subtle refraction when in the OFF state.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Glass Switch',
                          style: TextStyle(fontSize: 17)),
                      AdaptiveSwitch(
                        value: _switchValue,
                        onChanged: (v) => setState(() => _switchValue = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoSection(
                  'Refractive Sliders',
                  'The slider track has been upgraded to Liquid Glass. Observe how it bends the animated colored blobs passing behind it.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      AdaptiveSlider(
                        value: _sliderValue,
                        onChanged: (v) => setState(() => _sliderValue = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildInfoSection(
                  'Segmented Controls',
                  'Modernized controls following the iOS 26 "floating capsule" design language.',
                ),
                const SizedBox(height: 24),
                AdaptiveSegmentedControl<int>(
                  selectedValue: _segmentedValue,
                  values: const [0, 1, 2],
                  labels: const ['First', 'Second', 'Third'],
                  onValueChanged: (v) => setState(() => _segmentedValue = v),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static void _dummyOnChanged(dynamic v) {}

  Widget _buildSheetsDemo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoSection(
              'Detached Card Sheets',
              'Native sheets on iOS 26 adopt a "floating card" appearance. They are detached from the screen edges and use the high-fidelity glass material.',
            ),
            const SizedBox(height: 40),
            AdaptiveButton.glassProminent(
              onPressed: () {
                showAdaptiveCupertinoSheet(
                  context,
                  contentId: 'showcase-sheet',
                  isFloating: true,
                  detents: [
                    AdaptiveSheetDetent.medium,
                    AdaptiveSheetDetent.large
                  ],
                );
              },
              child: const Text('Show Native Sheet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenusDemo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInfoSection(
              'Glass Menus & Alerts',
              'Context menus and Alerts in iOS 26 use the new material stack. Long press the button below to see the context menu.',
            ),
            const SizedBox(height: 40),
            CupertinoContextMenu(
              actions: [
                CupertinoContextMenuAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Native Action 1'),
                ),
                CupertinoContextMenuAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Native Action 2'),
                ),
              ],
              child: AdaptiveButton.glass(
                onPressed: () {},
                child: const Text('Long Press Me'),
              ),
            ),
            const SizedBox(height: 32),
            AdaptiveButton.glassProminent(
              color: CupertinoColors.destructiveRed,
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Native Glass Alert'),
                    content: const Text(
                      'This dialog automatically inherits the iOS 26 material stack when running on a compatible device.',
                    ),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Show Native Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(text,
              style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: CupertinoColors.label.resolveFrom(context))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildVariantPreview(String name, AdaptiveButtonStyle style,
      {Color? color, required String description}) {
    return AdaptiveGlassBox(
      style: style,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: CupertinoColors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                  fontSize: 10, color: CupertinoColors.secondaryLabel),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Center(
              child: AdaptiveButton(
                style: style,
                color: color,
                onPressed: () {
                  // In True iOS 26, feedback is subtle (Lensing + Z-axis shift)
                  // We add a console log so you can see it's 100% active
                  print('📱 [Liquid Glass] Interaction registered: $name');
                  setState(() {});
                },
                child: Text(name.split(' ').first),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorphDemoUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AdaptiveButton.glass(
            glassEffectID: 'morph-demo-button',
            onPressed: () => setState(() => _isMorphed = !_isMorphed),
            child: Text(_isMorphed ? 'Morphed State' : 'Trigger Liquid Morph'),
          ),
          const SizedBox(height: 32),
          _buildInfoSection(
            'Liquid Morphing Bridge',
            'This button uses glassEffectID: "morph-demo-button". On iOS 26, the native system identifies this material and prepares it for fluid transitions into sheets or other glass elements sharing the same ID.',
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  _BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 120); // Softer blur

    final colors = [
      CupertinoColors.systemPurple.withOpacity(0.2), // Reduced opacity
      CupertinoColors.systemBlue.withOpacity(0.2),
      CupertinoColors.systemPink.withOpacity(0.15),
      CupertinoColors.systemYellow.withOpacity(0.1),
    ];

    for (var i = 0; i < colors.length; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * math.pi / 2);
      final offset = Offset(
        size.width / 2 + math.cos(angle) * 150, // Wider orbit
        size.height / 3 + math.sin(angle * 1.5) * 200,
      );
      canvas.drawCircle(offset, 180 + math.sin(angle) * 50,
          paint..color = colors[i]); // Larger circles
    }

    // NEW: Add sharp "Lensing Test" lines for high-fidelity verification
    final linePaint = Paint()
      ..color = CupertinoColors.white.withOpacity(0.08) // More subtle lines
      ..strokeWidth = 1.0;

    for (var i = 0; i < 15; i++) {
      final x =
          (size.width / 15 * i + (animationValue * size.width)) % size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}
