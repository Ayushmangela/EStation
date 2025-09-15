import 'package:flutter/material.dart';

// Imports for the views to be displayed
import '../map/map_view.dart';
import '../charging/charging_view.dart';
import '../battery/battery_view.dart';
import '../profile/profile_view.dart';

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> with TickerProviderStateMixin {
  double horizontalPadding = 25.0; // Changed from 40.0
  double horizontalMargin = 15.0;
  int noOfIcons = 4;

  List<IconData> icons = [
    Icons.map_outlined,
    Icons.ev_station,
    Icons.battery_charging_full,
    Icons.person_outline
  ];

  final List<Widget> _pages = [
    const UserMapView(),
    const ChargingView(),
    const BatteryView(),
    const ProfileView(),
  ];

  late double position;
  int selected = 0;

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 375));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    position = getEndPosition(0, horizontalPadding, horizontalMargin, noOfIcons);
    animation = Tween(begin: position, end: position).animate(controller);
  }

  double getEndPosition(int index, double horizontalPadding,
      double horizontalMargin, int noOfIcons) {
    double totalMargin = 2 * horizontalMargin;
    double totalPadding = 2 * horizontalPadding;
    double screenWidth = MediaQuery.of(context).size.width;
    double valueToOmit = totalMargin + totalPadding;

    if (noOfIcons == 0) return horizontalPadding;

    double iconZoneWidth = (screenWidth - valueToOmit) / noOfIcons;

    return (iconZoneWidth * index) + horizontalPadding + (iconZoneWidth / 2) - 70;
  }

  void animateDrop(int index) {
    double endPosition = getEndPosition(index, horizontalPadding, horizontalMargin, noOfIcons);
    animation = Tween(begin: position, end: endPosition)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    controller.forward().then((value) {
      if (mounted) {
        position = endPosition;
        controller.dispose();
        controller = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 575));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: selected,
            children: _pages,
          ),
          Positioned(
            bottom: horizontalMargin,
            left: horizontalMargin,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: AppBarPainter(animation.value),
                  size: Size(
                      (MediaQuery.of(context).size.width -
                          (2 * horizontalMargin)),
                      80.0),
                  child: SizedBox(
                    height: 120.0,
                    width: MediaQuery.of(context).size.width -
                        (2 * horizontalMargin),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: icons.asMap().entries.map<Widget>((entry) {
                          int idx = entry.key;
                          IconData icon = entry.value;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                animateDrop(idx);
                                selected = idx;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 375),
                              curve: Curves.easeOut,
                              height: 105,
                              width: (MediaQuery.of(context).size.width -
                                  (2 * horizontalMargin) -
                                  (2 * horizontalPadding)) /
                                  noOfIcons,
                              padding: const EdgeInsets.only(
                                  top: 17.5, bottom: 22.5),
                              alignment: selected == idx
                                  ? Alignment.topCenter
                                  : Alignment.bottomCenter,
                              child: SizedBox(
                                height: 35.0,
                                width: 35.0,
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration:
                                    const Duration(milliseconds: 575),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeOut,
                                    child: Icon(
                                      icon,
                                      key: ValueKey('icon_${icon.codePoint}'),
                                      size: 30.0,
                                      color: Colors.white, // fixed icon color
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class AppBarPainter extends CustomPainter {
  double x;

  AppBarPainter(this.x);

  double height = 80.0;
  double start = 40.0;
  double end = 120;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.black // navbar color
      ..style = PaintingStyle.fill;

    Path path = Path();
    path.moveTo(0.0, start);

    path.lineTo((x) < 20.0 ? 20.0 : x, start);
    path.quadraticBezierTo(20.0 + x, start, 30.0 + x, start + 30.0);
    path.quadraticBezierTo(40.0 + x, start + 55.0, 70.0 + x, start + 55.0);
    path.quadraticBezierTo(100.0 + x, start + 55.0, 110.0 + x, start + 30.0);
    path.quadraticBezierTo(120.0 + x, start, (140.0 + x) > (size.width - 20.0) ? (size.width - 20.0) : 140.0 + x, start);
    path.lineTo(size.width - 20.0, start);

    path.quadraticBezierTo(size.width, start, size.width, start + 25.0);
    path.lineTo(size.width, end - 25.0);
    path.quadraticBezierTo(size.width, end, size.width - 25.0, end);
    path.lineTo(25.0, end);
    path.quadraticBezierTo(0.0, end, 0.0, end - 25.0);
    path.lineTo(0.0, start + 25.0);
    path.quadraticBezierTo(0.0, start, 20.0, start);
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(x + 70.0, 50.0), 35.0, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
