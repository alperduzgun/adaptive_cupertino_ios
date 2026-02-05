import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'pages/bento_showcase_page.dart';
import 'pages/ios_26_settings_showcase.dart';
import 'pages/ios_26_showcase_page.dart';
import 'pages/profile_edit_sheet_content.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PERFORMANCE MONITORING 📊
  // SchedulerBinding.instance.addTimingsCallback((List<FrameTiming> timings) {
  //   if (timings.isEmpty) return;
  //   var totalRaster = 0;
  //   var totalBuild = 0;
  //   for (final timing in timings) {
  //     totalRaster += timing.rasterDuration.inMicroseconds;
  //     totalBuild += timing.buildDuration.inMicroseconds;
  //   }
  //   final avgRaster = totalRaster / timings.length / 1000.0;
  //   final avgBuild = totalBuild / timings.length / 1000.0;
  //   final totalFrameTime = avgRaster + avgBuild;

  //   // 16.6ms is target for 60fps, 8.3ms for 120fps (ProMotion)
  //   final fps = 1000 / totalFrameTime;

  //   // Only log significant drops or periodically to keep logs clean
  //   print(
  //       'FPS: ${fps.toStringAsFixed(1)} | Build: ${avgBuild.toStringAsFixed(2)}ms | Raster: ${avgRaster.toStringAsFixed(2)}ms');
  // });

  // Phase 3: Synchronous Version Pre-warming 🛡️⚡
  await IOSVersion.prewarm();

  // Phase 2: Register Sheet Content Factory (NATIVE FOCUSED)
  SheetContentFactory.register(
      'complex-sheet', () => const ComplexSheetContent());
  SheetContentFactory.register(
      'showcase-sheet', () => const ShowcaseSheetContent());
  SheetContentFactory.register(
      'bento-toolbar-page', () => const BentoShowcasePage());
  SheetContentFactory.register(
      'ios-26-showcase', () => const IOS26ShowcasePage());
  SheetContentFactory.register(
      'profile-edit-sheet', () => const ProfileEditSheetContent());

  runApp(const MyApp());
}

/// Phase 3: Dedicated Sheet Entry Point for Total Isolation 🛡️🧬
///
/// This entry point is used by isolated sibling engines spawned via
/// AdaptiveCupertinoSheetManager. It bypasses MyApp and HomePage entirely,
/// preventing "Back Button Bleed" and ensuring a clean navigator stack.
@pragma('vm:entry-point')
void adaptiveSheetEntrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 3: Synchronous Version Pre-warming 🛡️⚡
  await IOSVersion.prewarm();

  // Register the same factories so they are available in this isolate
  SheetContentFactory.register(
      'complex-sheet', () => const ComplexSheetContent());
  SheetContentFactory.register(
      'showcase-sheet', () => const ShowcaseSheetContent());

  runApp(const AdaptiveSheetApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Adaptive Cupertino iOS Demo',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      home: HomePage(),
      onGenerateRoute: onGenerateAdaptiveSheetRoute,
    );
  }
}

/// Minimal Isolated App for Sheets
class AdaptiveSheetApp extends StatelessWidget {
  const AdaptiveSheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Isolated Sheet',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      // NO home widget! The initial route will be handled by onGenerateRoute.
      onGenerateRoute: onGenerateAdaptiveSheetRoute,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  PreferredSizeWidget? _buildAppBar() {
    switch (_selectedIndex) {
      case 0:
        // Aether Settings has its own Scaffold and AppBar
        return null;
      case 1:
        return AdaptiveCupertinoToolbar(
          title: 'Titanium Glass',
          leadingAction: AdaptiveCupertinoAction(
            sfSymbolName: 'sparkles',
            onPressed: () {},
          ),
          trailingActions: [
            AdaptiveCupertinoAction(
              sfSymbolName: 'plus.circle.fill',
              onPressed: () {},
            ),
            AdaptiveCupertinoAction(
              sfSymbolName: 'person.crop.circle',
              onPressed: () {},
            ),
          ],
        );
      case 2:
        return const AdaptiveCupertinoAppBar(
          title: Text('TabBar Demo'),
          largeTitle: true,
        );
      case 3:
        return const AdaptiveCupertinoAppBar(
          title: Text('Combined Demo'),
        );
      case 4:
        return const AdaptiveCupertinoAppBar(
          title: Text('Legacy Showcase'),
          largeTitle: true,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🔍 DEBUG ICON DUMP [RUNTIME]:');
      print('sparkles: ${CupertinoIcons.sparkles.codePoint}');
      print('square_grid_2x2: ${CupertinoIcons.square_grid_2x2.codePoint}');
      print(
          'uiwindow_split_2x1: ${CupertinoIcons.uiwindow_split_2x1.codePoint}');
      print('layers_alt: ${CupertinoIcons.layers_alt.codePoint}');
      print('lab_flask: ${CupertinoIcons.lab_flask.codePoint}');
    }
    return Container(
      decoration: const BoxDecoration(
        color:
            CupertinoColors.black, // Pure Black Background requested by user 🖤
      ),
      child: AdaptiveScaffold(
        backgroundColor: const Color(0x00000000),
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(),
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            // 1. Aether Showcase (Default Launch Experience)
            AetherSettingsShowcase(),
            // 2. Bento Components
            BentoShowcasePage(),
            // 3. TabBar Demo
            TabBarDemoPage(),
            // 4. Combined Demo
            CombinedDemoPage(),
            // 5. Legacy Showcase (Hidden/Secondary)
            IOS26ShowcasePage(),
          ],
        ),
        bottomNavigationBar: AdaptiveCupertinoTabBar(
          items: const [
            AdaptiveCupertinoTabItem(
              label: 'Aether',
              icon: CupertinoIcons.sparkles,
              selectedIcon: CupertinoIcons.sparkles,
            ),
            AdaptiveCupertinoTabItem(
              label: 'Components',
              icon: CupertinoIcons.square_grid_2x2,
              selectedIcon: CupertinoIcons.square_grid_2x2_fill,
            ),
            AdaptiveCupertinoTabItem(
              label: 'Tabs',
              icon: CupertinoIcons.uiwindow_split_2x1,
              selectedIcon: CupertinoIcons.uiwindow_split_2x1,
            ),
            AdaptiveCupertinoTabItem(
              label: 'Sheets',
              icon: CupertinoIcons.layers_alt,
              selectedIcon: CupertinoIcons.layers_alt_fill,
              sfSymbolName: 'square.stack.3d.up', // Explicit Native Symbol 🛡️
              selectedSfSymbolName: 'square.stack.3d.up.fill',
            ),
            AdaptiveCupertinoTabItem(
              label: 'Legacy',
              icon: CupertinoIcons.lab_flask,
              selectedIcon: CupertinoIcons.lab_flask_solid,
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

// Tab Bar Demo Page
class TabBarDemoPage extends StatelessWidget {
  const TabBarDemoPage({super.key});

  // FIXED: No dynamic padding during scroll to avoid jitter.
  // The content starts under the expanded bar and flows naturally.
  double get _topPadding => 140.0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: SizedBox(height: _topPadding)), // Dynamic NativeBar spacing
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Adaptive TabBar',
                  'The tab bar at the bottom automatically uses:\n\n'
                      '• iOS 18+: Native UITabBar with Liquid Glass\n'
                      '• iOS <18: Standard CupertinoTabBar\n\n'
                      'Try scrolling and interacting with the tabs!',
                ),
                const SizedBox(height: 16),
                _buildFeatureList([
                  'Auto version detection',
                  'Smooth animations',
                  'SF Symbol icons',
                  'Badge support',
                  'Graceful fallback',
                ]),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text('Scroll Item #$index')),
              ),
            ),
            childCount: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Features:',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.activeGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(feature, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// AppBar Demo Page
class AppBarDemoPage extends StatelessWidget {
  const AppBarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('AppBar Demo'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Adaptive NavigationBar',
                  'The navigation bar at the top automatically uses:\n\n'
                      '• iOS 18+: Native UINavigationBar with Liquid Glass\n'
                      '• iOS <18: Standard CupertinoNavigationBar\n\n'
                      'Scroll down to see the appearance adapt!',
                ),
                const SizedBox(height: 16),
                _buildFeatureList([
                  'Liquid Glass blur',
                  'Large title support',
                  'Action buttons',
                  'Scroll edge effects',
                  'Auto fallback',
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Features:',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.activeGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(feature, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// Combined Demo Page
class CombinedDemoPage extends StatefulWidget {
  const CombinedDemoPage({super.key});

  @override
  State<CombinedDemoPage> createState() => _CombinedDemoPageState();
}

/// Extracted complex content for Phase 2 Isolated Sheets.
class ComplexSheetContent extends StatelessWidget {
  const ComplexSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000), // Transparent for Liquid Glass
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Isolated Dynamic Content'),
        backgroundColor: Color(0x00000000),
        border: null,
      ),
      child: SafeArea(
        child: ListView.builder(
          itemCount: 20,
          itemBuilder: (context, index) => CupertinoListTile(
            title: Text('Isolate Item $index'),
            subtitle: Text('Running in its own engine world #$index'),
            leading: Icon(
              index.isEven
                  ? CupertinoIcons.bolt_fill
                  : CupertinoIcons.flame_fill,
              color: index.isEven
                  ? CupertinoColors.systemYellow
                  : CupertinoColors.systemOrange,
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.info),
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Interaction Works!'),
                    content: Text(
                        'You tapped item $index inside an isolated isolate.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CombinedDemoPageState extends State<CombinedDemoPage> {
  @override
  Widget build(BuildContext context) {
    // No large title here, so spacing is standard 88.0 (44 + padding)
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
            child: SizedBox(height: 88)), // Standard Header spacing
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Combined Demo',
                  'Testing both AppBar and TabBar interactions together.',
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                _buildInfoCard(
                  'iOS 26 High-Fidelity',
                  'Experience the "North Star" of iOS native sheets:\n\n'
                      '• Floating 16pt Insets (Detached)\n'
                      '• Custom Detents (35%, 65%, 100%)\n'
                      '• Matched Transition (Morphing from button)',
                ),
                const SizedBox(height: 16),
                Center(
                  child: AdaptiveButton(
                    key: _highFidelityKey,
                    onPressed: () {
                      showAdaptiveCupertinoSheet(
                        context,
                        contentId: 'complex-sheet',
                        isFloating: true,
                        cornerRadius: 32.0,
                        sourceKey: _highFidelityKey,
                        customDetents: [0.35, 0.65, 1.0],
                      );
                    },
                    style: AdaptiveButtonStyle.filled,
                    child: const Text('Show High-Fidelity Sheet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  final GlobalKey _highFidelityKey = GlobalKey();

  Widget _buildInfoCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// Settings Page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // FIXED: No dynamic style change here to avoid feedback loops.
  double get _topPadding => 140.0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
            child: SizedBox(height: _topPadding)), // Dynamic NativeBar spacing
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.circle_fill,
                          size: 10, color: CupertinoColors.systemBlue),
                      const SizedBox(width: 12),
                      Text('Setting Option #$index'),
                      const Spacer(),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 14, color: CupertinoColors.systemGrey3),
                    ],
                  ),
                ),
              ),
            ),
            childCount: 30,
          ),
        ),
      ],
    );
  }
}

class ShowcaseSheetContent extends StatelessWidget {
  const ShowcaseSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Native Liquid Sheet'),
        backgroundColor: Color(0x00000000),
        border: null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                'High-Fidelity Material',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'This sheet is running in a fully isolated isolate. Notice how the glass material bends the main app content behind it.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AdaptiveButton.glass(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close Sheet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
