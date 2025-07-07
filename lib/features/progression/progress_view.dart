import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_state_service.dart';
import '../../constants/app_theme.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({Key? key}) : super(key: key);

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  DateTime selectedDate = DateTime.now();
  bool showWeekView = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateService>(
      builder: (context, appState, child) {
        return Scaffold(
          backgroundColor: AppTheme.primaryYellow,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header section with day streak
                  _buildHeaderSection(),
                  
                  // White section with calendar
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // Calendar section
                        _buildCalendarSection(),
                        
                        const SizedBox(height: 20),
                        
                        // Progress stats
                        _buildProgressStats(),
                        
                        const SizedBox(height: 40), // Bottom padding instead of Spacer
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Progress title
            Text(
              'Progress',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Streak display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppTheme.secondaryOrange,
                  size: 80,
                ),
                const SizedBox(width: 10),
                Text(
                  '3', // TODO: Connect to actual streak data
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 90,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            
            Text(
              'Day Streak',
              style: TextStyle(
                fontFamily: AppTheme.fontPoppins,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            // Calendar header
            Row(
              children: [
                Text(
                  'Streak Calendar',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.info_outline,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showWeekView = !showWeekView;
                    });
                  },
                  child: Row(
                    children: [
                      Text(
                        showWeekView ? 'Week' : 'Month',
                        style: TextStyle(
                          fontFamily: AppTheme.fontPoppins,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        showWeekView ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: AppTheme.primaryDark,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Month navigation (only show in month view)
            if (!showWeekView) ...[
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
                      });
                    },
                    icon: Icon(Icons.chevron_left, color: Colors.grey.shade600),
                  ),
                  Expanded(
                    child: Text(
                      _getMonthYearString(selectedDate),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontPoppins,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
                      });
                    },
                    icon: Icon(Icons.chevron_right, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ] else ...[
              // Just show current month for week view
              Text(
                _getMonthYearString(DateTime.now()),
                style: TextStyle(
                  fontFamily: AppTheme.fontPoppins,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Day headers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                  .map((day) => SizedBox(
                        width: 30,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTheme.fontPoppins,
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            
            const SizedBox(height: 10),
            
            // Calendar grid
            showWeekView ? _buildWeekView() : _buildMonthView(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final isToday = _isSameDay(date, now);
        final hasSession = index == 5; // Mock: 6th day has a session
        
        return _buildDayCell(date.day, isToday, hasSession);
      }),
    );
  }

  Widget _buildMonthView() {
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    return Column(
      children: [
        for (int week = 0; week < 6; week++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayOfWeek) {
                final dayNumber = week * 7 + dayOfWeek + 1 - firstWeekday;
                
                if (dayNumber <= 0 || dayNumber > daysInMonth) {
                  return const SizedBox(width: 30, height: 40);
                }
                
                final date = DateTime(selectedDate.year, selectedDate.month, dayNumber);
                final isToday = _isSameDay(date, DateTime.now());
                final hasSession = dayNumber == 6; // Mock: 6th day has a session
                
                return _buildDayCell(dayNumber, isToday, hasSession);
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell(int day, bool isToday, bool hasSession) {
    Color backgroundColor = Colors.transparent;
    Color textColor = AppTheme.primaryDark;
    
    if (hasSession) {
      backgroundColor = AppTheme.secondaryBlue;
      textColor = AppTheme.white;
    }
    
    return Container(
      width: 30,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: AppTheme.primaryYellow, width: 2) : null,
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: TextStyle(
            fontFamily: AppTheme.fontPoppins,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '1 day',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryYellow,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Highest Streak',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '1',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryYellow,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sessions completed',
                  style: TextStyle(
                    fontFamily: AppTheme.fontPoppins,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
} 