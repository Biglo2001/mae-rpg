import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Hintergrundbild (wie im Chat-Screen)
          Positioned.fill(
            child: Image.asset(
              'assets/hintergrund.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dunkler Overlay
          Container(
            color: const Color(0xFF140D07).withValues(alpha: 0.45),
          ),

          // Kartenfenster
          SafeArea(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EAD4),
                  border: Border.all(color: const Color(0xFF8A6421), width: 4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Karte",
                      style: TextStyle(
                        color: Color(0xFF2D1E10),
                        fontSize: 32,
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/map_1.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8A6421),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Zurück"),
                    ),
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
