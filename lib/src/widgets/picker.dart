import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An adaptive date picker that provides platform-appropriate selectors.
///
/// On iOS, it shows a native [UIDatePicker] with Glass aesthetics.
/// On Android, it shows the standard [showDatePicker] dialog.
Future<DateTime?> showAdaptiveDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS) {
    DateTime selectedDate = initialDate;

    // CHAOS SAFETY: Ensure dates are valid
    if (firstDate.isAfter(lastDate)) {
      final temp = firstDate;
      firstDate = lastDate;
      lastDate = temp;
    }

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => _NativePickerSheet(
        mode: 'date',
        initialDate: initialDate,
        minDate: firstDate,
        maxDate: lastDate,
        onChanged: (date) => selectedDate = date,
      ),
    );
    return selectedDate;
  }

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

/// An adaptive time picker that provides platform-appropriate selectors.
Future<TimeOfDay?> showAdaptiveTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS) {
    TimeOfDay selectedTime = initialTime;
    final now = DateTime.now();
    final initialDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime.hour,
      initialTime.minute,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => _NativePickerSheet(
        mode: 'time',
        initialDate: initialDateTime,
        onChanged: (date) {
          selectedTime = TimeOfDay.fromDateTime(date);
        },
      ),
    );
    return selectedTime;
  }

  return showTimePicker(
    context: context,
    initialTime: initialTime,
  );
}

class _NativePickerSheet extends StatefulWidget {
  final String mode;
  final DateTime initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final ValueChanged<DateTime> onChanged;

  const _NativePickerSheet({
    required this.mode,
    required this.initialDate,
    this.minDate,
    this.maxDate,
    required this.onChanged,
  });

  @override
  State<_NativePickerSheet> createState() => _NativePickerSheetState();
}

class _NativePickerSheetState extends State<_NativePickerSheet> {
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_cupertino_ios/picker_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onChanged') {
        final timestamp = call.arguments['date'] as double;
        final date = DateTime.fromMillisecondsSinceEpoch(
          (timestamp * 1000).toInt(),
        );
        widget.onChanged(date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: UiKitView(
              viewType: 'adaptive_cupertino_ios/picker',
              onPlatformViewCreated: _onPlatformViewCreated,
              creationParams: {
                'mode': widget.mode,
                'initialDate': widget.initialDate.millisecondsSinceEpoch / 1000,
                if (widget.minDate != null)
                  'minDate': widget.minDate!.millisecondsSinceEpoch / 1000,
                if (widget.maxDate != null)
                  'maxDate': widget.maxDate!.millisecondsSinceEpoch / 1000,
                'useGlass': true,
              },
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.mode == 'time' ? 'Select Time' : 'Select Date',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('Done'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
