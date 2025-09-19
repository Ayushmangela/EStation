import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

enum VehicleType { car, bike }

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate;
  String? _selectedTime;
  VehicleType? _selectedVehicleType; // Changed to nullable, defaults to null

  final List<String> _timeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
    "14:00 PM", "15:00 PM", "16:00 PM", "17:00 PM"
  ];

  late DateTime _firstBookableDay;
  late DateTime _lastBookableDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstBookableDay = DateTime(now.year, now.month, now.day);
    _lastBookableDay = _firstBookableDay.add(const Duration(days: 9));
    // _selectedDate = _firstBookableDay; // Don't pre-select date until vehicle is chosen
  }

  void _onDaySelected(DateTime selectedDay) {
    if (!_isDateBookable(selectedDay) || _selectedVehicleType == null) return;
    setState(() {
      _selectedDate = selectedDay;
      _focusedDate = selectedDay;
    });
  }

  bool _isDateBookable(DateTime date) {
    final dayToCheck = DateTime(date.year, date.month, date.day);
    return !dayToCheck.isBefore(_firstBookableDay) && !dayToCheck.isAfter(_lastBookableDay);
  }

  void _changeMonth(int monthDelta) {
    if (_selectedVehicleType == null) return; // Prevent month change if vehicle not selected
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + monthDelta, 1);
    });
  }

  Widget _buildVehicleTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildVehicleOption(
            label: "Car",
            icon: Icons.directions_car_filled_rounded,
            vehicleType: VehicleType.car,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildVehicleOption(
            label: "Bike",
            icon: Icons.two_wheeler_rounded,
            vehicleType: VehicleType.bike,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleOption({
    required String label,
    required IconData icon,
    required VehicleType vehicleType,
  }) {
    final bool isSelected = _selectedVehicleType == vehicleType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = vehicleType;
          if (_selectedDate == null) {
             _selectedDate = _firstBookableDay;
             _focusedDate = _firstBookableDay;
          }
        });
        debugPrint("Selected vehicle: $_selectedVehicleType");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade400 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade500 : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
              blurRadius: isSelected ? 6 : 4,
              offset: Offset(0, isSelected ? 3 : 2),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isVehicleSelected = _selectedVehicleType != null;
    final bool canConfirmBooking = isVehicleSelected && _selectedDate != null && _selectedTime != null;

    return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text(
            "Select Vehicle & Date",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 20)
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 80.0), // Added bottom padding for FAB
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "1. Choose Vehicle Type",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 15),
              _buildVehicleTypeSelector(),
              const SizedBox(height: 25),
              IgnorePointer(
                ignoring: !isVehicleSelected,
                child: Opacity(
                  opacity: isVehicleSelected ? 1.0 : 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "2. Select Date",
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 10),
                      _buildMonthHeader(),
                      const SizedBox(height: 15),
                      _buildCalendarDays(),
                      const SizedBox(height: 25),
                      Text(
                        "3. Choose Time",
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 15),
                      _buildTimeSlots(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton.extended(
                onPressed: canConfirmBooking 
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                            "Booking for ${_selectedVehicleType!.name} on ${DateFormat.yMMMd().format(_selectedDate!)} at $_selectedTime",
                          )),
                        );
                      }
                    : null,
                backgroundColor: canConfirmBooking ? Colors.green : Colors.grey.shade400,
                icon: Icon(
                  Icons.check,
                  color: canConfirmBooking ? Colors.white : Colors.grey.shade700,
                ),
                label: Text(
                  "Confirm Booking", 
                  style: TextStyle(
                    fontSize: 16, 
                    color: canConfirmBooking ? Colors.white : Colors.grey.shade700, 
                    fontWeight: FontWeight.w600
                  )
                ),
              ),
      );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.grey.shade700),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          DateFormat('MMMM yyyy').format(_focusedDate),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded, size: 20, color: Colors.grey.shade700),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildCalendarDays() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final weekDayOfFirstDay = firstDayOfMonth.weekday;
    final List<String> weekDayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    List<Widget> dayWidgets = [];

    for (var label in weekDayLabels) {
      dayWidgets.add(
        Expanded(
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
            ),
          ),
        ),
      );
    }

    int emptyCells = (weekDayOfFirstDay == 7) ? 0 : weekDayOfFirstDay;
    for (int i = 0; i < emptyCells; i++) {
      dayWidgets.add(Expanded(child: Container()));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDate = DateTime(_focusedDate.year, _focusedDate.month, day);
      final bool isSelected = _selectedDate != null && DateUtils.isSameDay(_selectedDate, currentDate);
      final bool isBookable = _isDateBookable(currentDate);
      final bool isToday = DateUtils.isSameDay(currentDate, DateTime.now());

      BoxDecoration decoration;
      TextStyle textStyle;

      if (isSelected) {
        decoration = BoxDecoration(
          color: Colors.green.shade400,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ]
        );
        textStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15);
      } else if (isBookable) {
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isToday ? Colors.green.shade300 : Colors.grey.shade300, width: 1.2),
          boxShadow: [
             BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
        );
        textStyle = TextStyle(color: isToday ? Colors.green.shade600 : Colors.black87, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 15);
      } else {
        decoration = BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        );
        textStyle = TextStyle(color: Colors.grey.shade400, fontSize: 14, decoration: TextDecoration.none);
      }

      dayWidgets.add(
        Expanded(
          child: GestureDetector(
            onTap: isBookable ? () => _onDaySelected(currentDate) : null,
            child: Container(
              margin: const EdgeInsets.all(4.5),
              height: 46,
              decoration: decoration,
              child: Center(
                child: Text('$day', style: textStyle),
              ),
            ),
          ),
        ),
      );
    }

    int totalCells = emptyCells + daysInMonth;
    int remainingCells = (7 - (totalCells % 7)) % 7;
    for (int i = 0; i < remainingCells; i++) {
      dayWidgets.add(Expanded(child: Container()));
    }

    List<Widget> calendarRows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      calendarRows.add(Row(children: dayWidgets.sublist(i, i + 7)));
      if (i < dayWidgets.length - 7) {
         calendarRows.add(const SizedBox(height: 7)); 
      }
    }

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0,4))]
        ),
        child: Column(children: calendarRows)
    );
  }

  Widget _buildTimeSlots() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final time = _timeSlots[index];
        final bool isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: (_selectedVehicleType != null) ? () {
            setState(() {
              _selectedTime = time;
            });
          } : null,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade400 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? Colors.green.shade500 : Colors.grey.shade300, 
                  width: 1.5
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                )
              ] : [
                 BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Center(
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
