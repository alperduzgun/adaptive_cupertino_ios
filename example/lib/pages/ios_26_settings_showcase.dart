import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AetherSettingsShowcase extends StatefulWidget {
  const AetherSettingsShowcase({super.key});

  @override
  State<AetherSettingsShowcase> createState() => _AetherSettingsShowcaseState();
}

class _AetherSettingsShowcaseState extends State<AetherSettingsShowcase> {
  final String _userName = 'Alper Duzgun';
  DateTime _birthday = DateTime(1990, 5, 20);
  bool _faceIdEnabled = true;
  bool _notificationsEnabled = true;
  int _securityLevel = 1; // 0: Standard, 1: Advanced, 2: Ultra
  bool _chaosMode = false;

  // New State for added components
  double _hapticIntensity = 0.5;
  int _interfaceMode = 0; // 0: Solid, 1: Fluid, 2: Vapor
  bool _useSpaciousToolbar = false;
  final GlobalKey _sheetSourceKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: const Color(0x00000000),
      extendBodyBehindAppBar: true,
      appBar: const AdaptiveCupertinoAppBar(
        title: Text('Aether Settings'),
        largeTitle: true,
      ),
      // NEW: Toolbar at bottom for quick actions
      bottomNavigationBar: AdaptiveCupertinoToolbar(
        isBottom: true,
        leadingAction: AdaptiveCupertinoAction(
            sfSymbolName: 'arrow.counterclockwise', onPressed: () {}),
        title: 'System Active',
        trailing: _useSpaciousToolbar
            ? [
                const Spacer(),
                const Icon(CupertinoIcons.gear),
                const Spacer(),
                const Icon(CupertinoIcons.ellipsis_circle),
              ] // Distributed layout
            : null,
        trailingActions: _useSpaciousToolbar
            ? null // Use widget list for spacers
            : [
                AdaptiveCupertinoAction(sfSymbolName: 'gear', onPressed: () {}),
                AdaptiveCupertinoAction(
                  sfSymbolName: 'ellipsis.circle',
                  onPressed: () {
                    debugPrint('Menu action tapped');
                  },
                ),
              ],
      ),

      floatingActionButton: AdaptiveFloatingActionButton(
        icon: const Icon(CupertinoIcons.sparkles),
        onPressed: () {
          showAdaptiveSnackBar(
            context,
            message: 'Aether configuration synchronized.',
            useGlass: true,
          );
        },
        useGlass: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                20,
                140,
                20,
                MediaQuery.paddingOf(context).bottom +
                    20), // Dynamic bottom padding
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed(
                [
                  _buildIdentitySection(),
                  const SizedBox(height: 32),
                  _buildProfileSection(),
                  const SizedBox(height: 32),
                  _buildControlSection(),
                  const SizedBox(height: 32),
                  _buildActionsSection(),
                  const SizedBox(height: 120), // Spacing for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return AdaptiveCard(
      useGlass: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const AdaptiveBadge(
              useGlass: true,
              label: Text('PRO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: CupertinoColors.systemGrey5,
                child: Icon(CupertinoIcons.person_fill,
                    size: 40, color: CupertinoColors.systemBlue),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const AdaptiveTooltip(
                    message:
                        'Your Aether account is secured with iOS 26 High-Fidelity Glass Encryption.',
                    useGlass: true,
                    child: Text(
                      'Aether Identity Verified',
                      style: TextStyle(
                          color: CupertinoColors.secondaryLabel, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return AdaptiveFormSection(
      header: 'IDENTITY & PROFILE',
      useGlass: true,
      children: [
        AdaptiveListTile(
          key: _sheetSourceKey, // Source for morphing transition
          title: const Text('Display Name'),
          subtitle: Text(_userName),
          trailing: const Icon(CupertinoIcons.pencil, size: 16),
          onTap: () async {
            // NEW: Use Native Sheet with Morphing
            showAdaptiveCupertinoSheet(
              context,
              contentId: 'profile-edit-sheet',
              isFloating: true,
              sourceKey: _sheetSourceKey,
              detents: [AdaptiveSheetDetent.medium, AdaptiveSheetDetent.large],
            );
          },
        ),
        AdaptiveListTile(
          title: const Text('Birthday'),
          subtitle:
              Text('${_birthday.day}/${_birthday.month}/${_birthday.year}'),
          onTap: () async {
            final date = await showAdaptiveDatePicker(
              context: context,
              initialDate: _birthday,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) setState(() => _birthday = date);
          },
        ),
      ],
    );
  }

  Widget _buildControlSection() {
    return Column(
      children: [
        // NEW: Segmented Control for Mode
        SizedBox(
          width: double.infinity,
          child: AdaptiveSegmentedControl<int>(
            selectedValue: _interfaceMode,
            onValueChanged: (v) => setState(() => _interfaceMode = v),
            values: const [0, 1, 2],
            labels: const ['Solid', 'Fluid', 'Vapor'],
          ),
        ),
        const SizedBox(height: 16),
        AdaptiveListTile(
          title: const Text('Spacious Toolbar'),
          subtitle: const Text('Use native Flexible Spacers'),
          trailing: AdaptiveSwitch(
            value: _useSpaciousToolbar,
            onChanged: (v) => setState(() => _useSpaciousToolbar = v),
          ),
        ),
        const SizedBox(height: 16),
        AdaptiveExpansionTile(
          title: const Text('Security Controls'),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // NEW: Slider for Haptics
                  const Row(
                    children: [
                      Icon(CupertinoIcons.waveform,
                          size: 20, color: CupertinoColors.systemGrey),
                      SizedBox(width: 12),
                      Text('Haptic Intensity'),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('0%',
                          style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel)),
                      Expanded(
                        child: AdaptiveSlider(
                          value: _hapticIntensity,
                          onChanged: (v) =>
                              setState(() => _hapticIntensity = v),
                        ),
                      ),
                      const Text('100%',
                          style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Face ID Authentication'),
                      AdaptiveSwitch(
                        value: _faceIdEnabled,
                        onChanged: (v) => setState(() => _faceIdEnabled = v),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Encrypted Notifications'),
                      AdaptiveCheckbox(
                        value: _notificationsEnabled,
                        onChanged: (v) =>
                            setState(() => _notificationsEnabled = v!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdaptiveFormSection(
          header: 'SECURITY LEVEL',
          useGlass: true,
          children: [
            AdaptiveListTile(
              title: const Text('Standard Mode'),
              trailing: AdaptiveRadio<int>(
                value: 0,
                groupValue: _securityLevel,
                onChanged: (v) => setState(() => _securityLevel = v!),
              ),
            ),
            AdaptiveListTile(
              title: const Text('Advanced Mode'),
              trailing: AdaptiveRadio<int>(
                value: 1,
                groupValue: _securityLevel,
                onChanged: (v) => setState(() => _securityLevel = v!),
              ),
            ),
            AdaptiveListTile(
              title: const Text('Ultra Secure'),
              trailing: AdaptiveRadio<int>(
                value: 2,
                groupValue: _securityLevel,
                onChanged: (v) => setState(() => _securityLevel = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AdaptiveFormSection(
          header: 'NATIVE ANIMATIONS (iOS 26)',
          useGlass: true,
          children: [
            AdaptiveListTile(
              title: const Text('Live Status'),
              subtitle: const Text('SF Symbol with Pulse Effect'),
              trailing: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const AdaptiveBadge(
                  sfSymbol: 'wifi',
                  effect: 'pulse',
                  useGlass: true,
                  labelColor: CupertinoColors
                      .black, // Dark icon for visibility on glass
                  child: Icon(CupertinoIcons.circle_fill,
                      color: CupertinoColors.systemGrey6, size: 32),
                ),
              ),
            ),
            AdaptiveListTile(
              title: const Text('Notifications'),
              subtitle: const Text('SF Symbol with Bounce Effect'),
              trailing: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const AdaptiveBadge(
                  sfSymbol: 'bell.fill',
                  effect: 'bounce',
                  backgroundColor: CupertinoColors.systemOrange,
                  child: Icon(CupertinoIcons.app_fill,
                      color: CupertinoColors.systemGrey6, size: 32),
                ),
              ),
            ),
            AdaptiveListTile(
              title: const Text('Server Sync'),
              subtitle: const Text('SF Symbol with Variable Color Effect'),
              trailing: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const AdaptiveBadge(
                  sfSymbol: 'antenna.radiowaves.left.and.right',
                  effect: 'variableColor',
                  useGlass: true,
                  labelColor: CupertinoColors.systemBlue,
                  child: Icon(CupertinoIcons.circle_fill,
                      color: CupertinoColors.systemGrey6, size: 32),
                ),
              ),
            ),
            AdaptiveListTile(
              title: const Text('Cloud Storage'),
              subtitle: const Text('SF Symbol with Scale Effect'),
              trailing: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const AdaptiveBadge(
                  sfSymbol: 'icloud.fill',
                  effect: 'scale',
                  backgroundColor: CupertinoColors.systemBlue,
                  child: Icon(CupertinoIcons.app_fill,
                      color: CupertinoColors.systemGrey6, size: 32),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return AdaptiveFormSection(
      header: 'SYSTEM ACTIONS',
      useGlass: true,
      children: [
        AdaptiveListTile(
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemIndigo,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ID',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: const Text('Account Management'),
          subtitle: const Text('Tap for details, hold for actions'),
          trailing: const Icon(CupertinoIcons.brightness,
              size: 16, color: CupertinoColors.systemGrey2),
          useGlass: true, // Internal glass for the tile
          onTap: () {
            showAdaptiveSnackBar(context, message: 'Account Details');
          },
          contextMenuActions: [
            AdaptiveContextMenuItem(
              child: const Text('Copy ID'),
              icon: 'doc.on.doc',
              onPressed: () {
                showAdaptiveSnackBar(context,
                    message: 'ID Copied to Clipboard', useGlass: true);
              },
            ),
            AdaptiveContextMenuItem(
              child: const Text('Share Profile'),
              icon: 'square.and.arrow.up',
              onPressed: () {
                // Share logic
              },
            ),
            AdaptiveContextMenuItem(
              child: const Text('Deactivate'),
              icon: 'trash',
              isDestructive: true,
              onPressed: () {
                // Destructive logic
              },
            ),
          ],
        ),
        AdaptiveListTile(
          title: const Text('Chaos Engineering Mode'),
          trailing: AdaptiveSwitch(
            value: _chaosMode,
            onChanged: (v) => setState(() => _chaosMode = v),
          ),
        ),
        const SizedBox(height: 16),
        // Button Showcase Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton.glassProminent(
                  onPressed: () {},
                  child: const Text('Initiate System Diagnostics'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AdaptiveButton.glassTinted(
                      tintColor: CupertinoColors.systemPink,
                      onPressed: () {},
                      child: const Text('Purge Cache'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AdaptiveButton(
                      style: AdaptiveButtonStyle.glass,
                      onPressed: () {},
                      icon: const Icon(CupertinoIcons.share),
                      child: const Text('Export Log'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton.glassClear(
                  onPressed: () {},
                  child: const Text('Reset All Configurations'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
