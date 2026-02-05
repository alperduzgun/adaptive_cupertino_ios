import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter/cupertino.dart';

class ProfileEditSheetContent extends StatefulWidget {
  const ProfileEditSheetContent({super.key});

  @override
  State<ProfileEditSheetContent> createState() =>
      _ProfileEditSheetContentState();
}

class _ProfileEditSheetContentState extends State<ProfileEditSheetContent> {
  String _name = 'Alper Duzgun';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Edit Profile'),
        backgroundColor: Color(0x00000000),
        border: null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              AdaptiveCard(
                useGlass: true,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      AdaptiveTextField(
                        placeholder: 'Display Name',
                        useGlass: true,
                        onChanged: (v) => setState(() => _name = v),
                        controller: TextEditingController(text: _name),
                      ),
                      const SizedBox(height: 16),
                      // Mock Picker for Region
                      const Text(
                        'Select Region',
                        style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) {},
                          children: const [
                            Text('San Francisco'),
                            Text('Istanbul'),
                            Text('Neo-Tokyo'),
                            Text('Mars Colony'),
                            Text('Aether Station'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              AdaptiveButton.glass(
                onPressed: () {
                  // In a real app, we would sync data back via MethodChannel
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
