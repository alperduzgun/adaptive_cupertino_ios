/// Native iOS Cupertino widgets with adaptive platform support.
///
/// This library provides iOS 18+ Liquid Glass design with automatic fallback
/// for older iOS versions. All widgets automatically detect iOS version and
/// use native implementations when available.
library adaptive_cupertino_ios;

// App
export 'src/app/adaptive_app.dart';

// Widgets
export 'src/widgets/action.dart';
export 'src/widgets/app_bar.dart';
export 'src/widgets/button.dart';
export 'src/widgets/dialog.dart';
export 'src/widgets/scaffold.dart';
export 'src/widgets/segmented_control.dart';
export 'src/widgets/tab_bar.dart';
export 'src/widgets/toolbar.dart';

// Platform
export 'src/platform/bridge.dart';
export 'src/platform/ios_version.dart';
