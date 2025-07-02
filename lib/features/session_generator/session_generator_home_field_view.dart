import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../widgets/bravo_button.dart';

class SessionGeneratorHomeFieldView extends StatelessWidget {
  const SessionGeneratorHomeFieldView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final yellow = const Color(0xFFF9CC53);
    final darkGray = const Color(0xFF444444);
    final greenBg = const Color(0xFF70D412);
    final messageGreen = const Color(0xFF60AE17);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top bar (white, compact)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF86C9F7), size: 28),
                    ),
                    const Spacer(),
                    Text(
                      'BravoBall',
                      style: TextStyle(
                        fontFamily: 'PottaOne',
                        fontSize: 26,
                        color: yellow,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 2.0),
                          child: Icon(Icons.local_fire_department, color: Colors.orange, size: 26),
                        ),
                        Text('0', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 22, color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main scrollable content
          Expanded(
            child: Container(
              color: greenBg,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Field area with Rive background and overlays
                    SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          // Rive field background
                          Positioned.fill(
                            child: RiveAnimation.asset(
                              'assets/rive/Grass_Field.riv',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          // Message bubble
                          Positioned(
                            top: 100,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              decoration: BoxDecoration(
                                color: messageGreen,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                'You have 5 drills\nto complete.',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          // Bravo and Backpack
                          Positioned(
                            top: 200,
                            left: screenWidth * 0.22,
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: RiveAnimation.asset(
                                'assets/rive/Bravo_Animation.riv',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 200,
                            right: screenWidth * 0.22,
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: RiveAnimation.asset(
                                'assets/rive/Backpack.riv',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Begin button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: BravoButton(
                        text: 'Begin',
                        onPressed: () {},
                        color: yellow,
                        textColor: Colors.white,
                        height: 56,
                        textSize: 21,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Drill path (vertical)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _DrillCircle(active: true),
                        const SizedBox(height: 28),
                        _DrillCircle(active: false),
                        const SizedBox(height: 28),
                        _DrillCircle(active: false),
                        const SizedBox(height: 28),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrillCircle extends StatelessWidget {
  final bool active;
  const _DrillCircle({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.grey.shade300,
        shape: BoxShape.circle,
        boxShadow: [
          if (active)
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Center(
        child: Icon(Icons.directions_run, size: 38, color: active ? Colors.redAccent : Colors.grey),
      ),
    );
  }
} 