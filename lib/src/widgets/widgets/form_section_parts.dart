part of '../form_section.dart';

class _CupertinoFormSectionWidget extends StatelessWidget {
  final String? header;
  final String? footer;
  final List<Widget> children;
  final bool useGlass;

  const _CupertinoFormSectionWidget({
    this.header,
    this.footer,
    required this.children,
    this.useGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useGlass && Theme.of(context).platform == TargetPlatform.iOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8, top: 16),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  letterSpacing: -0.1,
                ),
              ),
            ),
          Stack(
            children: [
              Positioned.fill(
                child: UiKitView(
                  viewType: 'adaptive_cupertino_ios/form_section',
                  creationParams: const {
                    'useGlass': true,
                  },
                  creationParamsCodec: const StandardMessageCodec(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i < children.length - 1)
                        const Padding(
                          padding: EdgeInsets.only(left: 60),
                          child: Divider(
                            height: 0.5,
                            thickness: 0.5,
                            color: CupertinoColors.separator,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 8),
              child: Text(
                footer!,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
        ],
      );
    }

    return CupertinoFormSection.insetGrouped(
      header: header != null ? Text(header!) : null,
      footer: footer != null ? Text(footer!) : null,
      children: children,
    );
  }
}

class _MaterialFormSectionWidget extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const _MaterialFormSectionWidget({
    this.header,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              header!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
