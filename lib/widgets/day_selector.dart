import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onChanged;

  const DaySelector({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = today.subtract(Duration(days: index));
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onChanged(index),
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
                    _weekday(day.weekday),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.black : Colors.grey,
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

  String _weekday(int day) {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return names[day - 1];
  }
}
