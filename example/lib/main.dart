import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 3: Synchronous Version Pre-warming 🛡️⚡
  await IOSVersion.prewarm();

  // Phase 2: Register Sheet Content Factory (NATIVE FOCUSED)
  // This must be in main() to be visible to isolated sibling engines.
  SheetContentFactory.register(
      'complex-sheet', () => const ComplexSheetContent());

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

  static const List<Widget> _pages = [
    TabBarDemoPage(),
    AppBarDemoPage(),
    CombinedDemoPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          // App Bar at top
          AdaptiveCupertinoAppBar(
            title: const Text('adaptive_cupertino_ios'),
            largeTitle: false,
            trailing: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.info_circle),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('About'),
                      content: const Text(
                        'This app demonstrates the adaptive_cupertino_ios package.\n\n'
                        'iOS 18+: Native Liquid Glass UI\n'
                        'iOS <18: Standard Cupertino widgets',
                      ),
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
            ],
          ),

          // Content
          Expanded(
            child: _pages[_selectedIndex],
          ),

          // Tab Bar at bottom
          AdaptiveCupertinoTabBar(
            items: const [
              AdaptiveCupertinoTabItem(
                label: 'TabBar Demo',
                icon: CupertinoIcons.square_grid_2x2,
                selectedIcon: CupertinoIcons.square_grid_2x2_fill,
              ),
              AdaptiveCupertinoTabItem(
                label: 'AppBar Demo',
                icon: CupertinoIcons.rectangle_stack,
                selectedIcon: CupertinoIcons.rectangle_stack_fill,
              ),
              AdaptiveCupertinoTabItem(
                label: 'Combined',
                icon: CupertinoIcons.layers,
                selectedIcon: CupertinoIcons.layers_fill,
              ),
              AdaptiveCupertinoTabItem(
                label: 'Settings',
                icon: CupertinoIcons.gear,
                selectedIcon: CupertinoIcons.gear_solid,
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}

// Tab Bar Demo Page
class TabBarDemoPage extends StatelessWidget {
  const TabBarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('TabBar Demo'),
        ),
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
    return CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Combined Demo'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Full Experience',
                  'This page shows both AppBar and TabBar working together.\n\n'
                      'On iOS 18+, you\'re seeing the full Liquid Glass experience with '
                      'native blur effects and fluid animations.',
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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text('Settings'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CupertinoListSection.insetGrouped(
                  header: const Text('About'),
                  children: [
                    CupertinoListTile(
                      title: const Text('Package'),
                      subtitle: const Text('adaptive_cupertino_ios'),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      title: const Text('Version'),
                      subtitle: const Text('0.1.0'),
                      onTap: () {},
                    ),
                  ],
                ),
                CupertinoListSection.insetGrouped(
                  header: const Text('Features'),
                  children: [
                    CupertinoListTile(
                      title: const Text('Adaptive TabBar'),
                      subtitle: const Text('iOS 18+ Liquid Glass support'),
                      leading: const Icon(
                        CupertinoIcons.square_grid_2x2,
                        color: CupertinoColors.systemBlue,
                      ),
                      onTap: () {},
                    ),
                    CupertinoListTile(
                      title: const Text('Adaptive AppBar'),
                      subtitle: const Text('Native UINavigationBar'),
                      leading: const Icon(
                        CupertinoIcons.rectangle_stack,
                        color: CupertinoColors.systemGreen,
                      ),
                      onTap: () {},
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
}
