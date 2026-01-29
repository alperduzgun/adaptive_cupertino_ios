import 'package:flutter/cupertino.dart';
import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Adaptive Cupertino iOS Demo',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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
  const TabBarDemoPage({Key? key}) : super(key: key);

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
  const AppBarDemoPage({Key? key}) : super(key: key);

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
class CombinedDemoPage extends StatelessWidget {
  const CombinedDemoPage({Key? key}) : super(key: key);

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
                _buildInfoCard(
                  'Native Bottom Sheet',
                  'Trigger a truly native iOS bottom sheet with Liquid Glass effects.\n\n'
                      '• iOS 26+: Floating 16pt geometry + UIGlassEffect\n'
                      '• Supports Detents (Medium/Large)\n'
                      '• Interactive dismissal',
                ),
                const SizedBox(height: 16),
                Center(
                  child: AdaptiveButton(
                    onPressed: () {
                      showAdaptiveCupertinoSheet(
                        context,
                        child: const Center(
                          child: Text('Native Sheet Content'),
                        ),
                        detents: [
                          AdaptiveSheetDetent.medium,
                          AdaptiveSheetDetent.large,
                        ],
                      );
                    },
                    style: AdaptiveButtonStyle.filled,
                    child: const Text('Show Native Sheet'),
                  ),
                ),
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
}

// Settings Page
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
