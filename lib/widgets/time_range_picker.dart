import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimeRangePicker extends StatefulWidget {
  final String initialStartTime;
  final String initialEndTime;
  final Function(String timeRange) onTimeRangeSelected;

  const TimeRangePicker({
    super.key,
    required this.initialStartTime,
    required this.initialEndTime,
    required this.onTimeRangeSelected,
  });

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = _parseTime(widget.initialStartTime);
    _endTime = _parseTime(widget.initialEndTime);
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length == 2) {
        int hour = int.parse(parts[0].trim());
        int minute = int.parse(parts[1].trim());
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return const TimeOfDay(hour: 9, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getTimeRange() {
    return '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}';
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteTextColor: AppColors.textPrimary,
              dialHandColor: AppColors.coral,
              dialBackgroundColor: AppColors.surface2,
              hourMinuteColor: AppColors.surface2,
              dayPeriodColor: AppColors.coral,
              dayPeriodTextColor: Colors.white,
              dayPeriodBorderSide: BorderSide.none,
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
        // Si l'heure de début est après l'heure de fin, ajuster la fin
        if (_startTime.hour > _endTime.hour ||
            (_startTime.hour == _endTime.hour && _startTime.minute >= _endTime.minute)) {
          _endTime = TimeOfDay(
            hour: _startTime.hour + 1,
            minute: _startTime.minute,
          );
        }
      });
      widget.onTimeRangeSelected(_getTimeRange());
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.surface,
              hourMinuteTextColor: AppColors.textPrimary,
              dialHandColor: AppColors.coral,
              dialBackgroundColor: AppColors.surface2,
              hourMinuteColor: AppColors.surface2,
              dayPeriodColor: AppColors.coral,
              dayPeriodTextColor: Colors.white,
              dayPeriodBorderSide: BorderSide.none,
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endTime) {
      // Vérifier que l'heure de fin est après l'heure de début
      if (picked.hour < _startTime.hour ||
          (picked.hour == _startTime.hour && picked.minute <= _startTime.minute)) {
        _showErrorSnackBar(context, "L'heure de fin doit être après l'heure de début");
        return;
      }
      setState(() {
        _endTime = picked;
      });
      widget.onTimeRangeSelected(_getTimeRange());
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.statusAnnulee,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TimePickerButton(
            label: 'Début',
            time: _formatTimeOfDay(_startTime),
            onTap: _selectStartTime,
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, color: AppColors.coral, size: 20),
        ),
        Expanded(
          child: _TimePickerButton(
            label: 'Fin',
            time: _formatTimeOfDay(_endTime),
            onTap: _selectEndTime,
          ),
        ),
      ],
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.coral),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}