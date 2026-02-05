import 'dart:math' as math;

import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;

enum ShowcaseFeature {
  none,
  lensing,
  variants,
  controls,
  sheets,
  menus,
  forms,
  lists
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

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) =>
          CustomPaint(painter: _BackgroundPainter(_bgController.value)),
    );
  }

  Widget _buildMenu() {
    return CustomScrollView(
      slivers: [
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
              const SizedBox(height: 16),
              _buildMenuCard(
                'Forms & Inputs',
                'Adaptive TextFields, Checkboxes, and Radios with native Glass support.',
                CupertinoIcons.textformat_abc_dottedunderline,
                ShowcaseFeature.forms,
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                'Lists & Layouts',
                'High-fidelity Bento grids, Cards, and Floating Action Buttons.',
                CupertinoIcons.square_grid_2x2,
                ShowcaseFeature.lists,
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
  bool _showBackground = true;
  bool _checkboxValue = false;
  int _radioValue = 0;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bgController =
        AnimationController(vsync: this, duration: const Duration(seconds: 40))
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
      case ShowcaseFeature.controls:
        return 'Controls';
      case ShowcaseFeature.sheets:
        return 'Sheets';
      case ShowcaseFeature.menus:
        return 'Menus & Dialogs';
      case ShowcaseFeature.forms:
        return 'Forms & Inputs';
      case ShowcaseFeature.lists:
        return 'Lists & Layouts';
      case ShowcaseFeature.none:
        return 'Detail';
    }
  }

  Widget _buildActiveContent() {
    switch (widget.feature) {
      case ShowcaseFeature.lensing:
        return _buildLensingDemo();
      case ShowcaseFeature.variants:
        return _buildVariantsDemo();
      case ShowcaseFeature.sheets:
        return _buildSheetsDemo();
      case ShowcaseFeature.menus:
        return _buildMenusDemo();
      case ShowcaseFeature.forms:
        return _buildFormsDemo();
      case ShowcaseFeature.lists:
        return _buildListsDemo();
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
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildInfoSection(
                'Aesthetical Variants',
                'Each variant provides a unique material response. Identity variant tints the glass with your brand color while maintaining 100% transparency.',
              ),
              const SizedBox(height: 32),
              _buildVariantCard('Glass Variant', 'Default high-fidelity blur',
                  AdaptiveButtonStyle.glass),
              const SizedBox(height: 16),
              _buildVariantCard(
                  'Identity Variant',
                  'Brand tinted refraction',
                  AdaptiveButtonStyle.glassIdentity,
                  CupertinoColors.activeBlue),
              const SizedBox(height: 16),
              _buildVariantCard('Clear Variant', 'Minimalist transparency',
                  AdaptiveButtonStyle.glassClear),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetsDemo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInfoSection('Floating Sheets', 'Native iOS 26 detached style.'),
          const SizedBox(height: 32),
          AdaptiveButton(
            onPressed: () {
              showAdaptiveCupertinoSheet(
                context,
                contentId: 'showcase-sheet',
                isFloating: true,
              );
            },
            child: const Text('Show Native Sheet'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenusDemo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildInfoSection('Context Menus', 'Long-press to trigger.'),
          const SizedBox(height: 32),
          AdaptiveContextMenu(
            actions: [
              AdaptiveContextMenuItem(
                child: const Text('Edit'),
                onPressed: () {},
              ),
              AdaptiveContextMenuItem(
                child: const Text('Share'),
                onPressed: () {},
              ),
              AdaptiveContextMenuItem(
                child: const Text('Delete'),
                onPressed: () {},
              ),
            ],
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                  child: Text('Long Press Me',
                      style: TextStyle(color: CupertinoColors.activeBlue))),
            ),
          ),
          const SizedBox(height: 48),
          _buildInfoSection('Badges & Tooltips', 'Glass-textured info layers.'),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AdaptiveTooltip(
                message: 'This is a premium glass tooltip',
                useGlass: true,
                child: AdaptiveBadge(
                  label: const Text('99+'),
                  useGlass: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(CupertinoIcons.bell_fill),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              AdaptiveButton(
                onPressed: () => showAdaptiveSnackBar(
                  context,
                  message: 'Native iOS 26 Top Banner triggered!',
                  useGlass: true,
                ),
                child: const Text('Show Banner'),
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildInfoSection('Glass Dialogs', 'Consistent material blending.'),
          const SizedBox(height: 32),
          AdaptiveButton(
            onPressed: () {
              showAdaptiveDialog(
                context: context,
                builder: (context) => AdaptiveAlertDialog(
                  title: const Text('Native iOS 26'),
                  content: const Text(
                      'This dialog uses real-time glass refraction.'),
                  actions: [
                    AdaptiveDialogAction(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Show Glass Dialog'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsDemo() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoSection(
                  'Bento Forms',
                  'iOS 26 style grouped sections using real-time glass refraction.',
                ),
                const SizedBox(height: 24),
                AdaptiveFormSection(
                  header: 'Account Information',
                  useGlass: true,
                  children: [
                    AdaptiveTextField(
                      controller: _textController,
                      placeholder: 'Full Name',
                      useGlass:
                          false, // Inside section, we don't need extra glass
                    ),
                    const AdaptiveTextField(
                      placeholder: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      useGlass: false,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AdaptiveFormSection(
                  header: 'Preferences',
                  footer: 'These settings are applied across all your devices.',
                  useGlass: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Enable Notifications'),
                          AdaptiveCheckbox(
                            value: _checkboxValue,
                            onChanged: (v) =>
                                setState(() => _checkboxValue = v ?? false),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Priority Mode'),
                          Row(
                            children: [
                              AdaptiveRadio<int>(
                                value: 0,
                                groupValue: _radioValue,
                                onChanged: (v) =>
                                    setState(() => _radioValue = v ?? 0),
                              ),
                              const Text('Low'),
                              const SizedBox(width: 8),
                              AdaptiveRadio<int>(
                                value: 1,
                                groupValue: _radioValue,
                                onChanged: (v) =>
                                    setState(() => _radioValue = v ?? 1),
                              ),
                              const Text('High'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildInfoSection(
                  'Standalone Glass',
                  'A text field with its own independent glass refraction layer.',
                ),
                const SizedBox(height: 16),
                const AdaptiveTextField(
                  placeholder: 'Independent Glass Input',
                  useGlass: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, String desc) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: CupertinoColors.secondaryLabel)),
      ],
    );
  }

  Widget _buildListsDemo() {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoSection(
                  'Bento Layouts',
                  'iOS 26 cards and list tiles using real-time refraction and adaptive materials.',
                ),
                const SizedBox(height: 24),
                AdaptiveCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      AdaptiveListTile(
                        leading: const Icon(CupertinoIcons.person_fill),
                        title: const Text('Profile Settings'),
                        trailing:
                            const Icon(CupertinoIcons.chevron_right, size: 14),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 56),
                      AdaptiveListTile(
                        leading: const Icon(CupertinoIcons.heart_fill),
                        title: const Text('Favorites'),
                        trailing:
                            const Icon(CupertinoIcons.chevron_right, size: 14),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(
                      child: AdaptiveCard(
                        borderRadius: 24,
                        child: Column(
                          children: [
                            Icon(CupertinoIcons.chart_bar_fill,
                                size: 32, color: CupertinoColors.activeBlue),
                            SizedBox(height: 12),
                            Text('Stats',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: AdaptiveCard(
                        borderRadius: 24,
                        child: Column(
                          children: [
                            Icon(CupertinoIcons.cloud_fill,
                                size: 32, color: CupertinoColors.systemTeal),
                            SizedBox(height: 12),
                            Text('Cloud',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const AdaptiveExpansionTile(
                  leading: Icon(CupertinoIcons.info),
                  title: Text('Advanced Information'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'This section contains additional details about the bento layout and its adaptive behavior.'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantCard(String name, String desc, AdaptiveButtonStyle style,
      [Color? color]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
                Text(desc,
                    style: const TextStyle(
                        fontSize: 12, color: CupertinoColors.secondaryLabel)),
              ],
            ),
          ),
          AdaptiveButton(
            style: style,
            color: color,
            onPressed: () {},
            child: const Text('Action'),
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
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    final colors = [
      CupertinoColors.systemPurple.withOpacity(0.2),
      CupertinoColors.systemBlue.withOpacity(0.2),
      CupertinoColors.systemPink.withOpacity(0.15),
      CupertinoColors.systemYellow.withOpacity(0.1),
    ];

    for (var i = 0; i < colors.length; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * math.pi / 2);
      final offset = Offset(
        size.width / 2 + math.cos(angle) * 150,
        size.height / 3 + math.sin(angle * 1.5) * 200,
      );
      canvas.drawCircle(
          offset, 180 + math.sin(angle) * 50, paint..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}
