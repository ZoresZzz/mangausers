import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekdaySelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onChanged;

  const WeekdaySelector({
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (_, i) {
          final date = startOfWeek.add(Duration(days: i));
          final isSelected = DateUtils.isSameDay(date, selectedDate);

          return GestureDetector(
            onTap: () => onChanged(date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
