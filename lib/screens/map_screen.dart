import 'package:flutter/material.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapGrid? _mapGrid;

  final Map<String, Color> _terrainColors = {
    'F': const Color.fromRGBO(34, 139, 34, 0.45), // Forest green
    'P': const Color.fromRGBO(210, 180, 140, 0.45), // Plains
    'M': const Color.fromRGBO(180, 180, 180, 0.45), // Mountains
    'O': const Color.fromRGBO(30, 144, 255, 0.45), // Ocean dodgerblue
    '.': const Color.fromRGBO(0, 0, 0, 0), // Out of map (transparent)
    '': const Color.fromRGBO(0, 0, 0, 0), // Empty (transparent)
  };

  @override
  void initState() {
    super.initState();
    _loadMapGrid();
  }

  Future<void> _loadMapGrid() async {
    final String data = await DefaultAssetBundle.of(context).loadString('assets/map3_large.maegrid.txt');
    setState(() {
      _mapGrid = MapGrid.parse(data);
    });
  }

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
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/map3.png',
                              fit: BoxFit.contain,
                            ),
                            if (_mapGrid != null)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: MapGridPainter(
                                    mapGrid: _mapGrid!,
                                    terrainColors: _terrainColors,
                                  ),
                                ),
                              ),
                          ],
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

class MapGrid {
  final int gridX;
  final int gridY;
  final List<List<String>> grid;

  MapGrid({required this.gridX, required this.gridY, required this.grid});

  factory MapGrid.parse(String data) {
    final lines = data.split('\r\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) {
      throw FormatException("Map grid data is empty.");
    }

    final header = lines[0].split(' ');
    if (header.length < 4 || header[0] != 'GRIDX' || header[2] != 'GRIDY') {
      throw FormatException("Invalid map grid header: ${lines[0]}");
    }

    final gridX = int.parse(header[1]);
    final gridY = int.parse(header[3]);

    final List<List<String>> grid = [];
    for (int i = 1; i <= gridY; i++) {
      if (i >= lines.length) {
        throw FormatException("Insufficient grid data for GRIDY=$gridY. Missing row ${i - 1}");
      }
      final row = lines[i].split(' ').where((e) => e.isNotEmpty).toList();
      if (row.length != gridX) {
        throw FormatException("Row ${i - 1} has ${row.length} cells, expected $gridX.");
      }
      grid.add(row);
    }

    return MapGrid(gridX: gridX, gridY: gridY, grid: grid);
  }
}

class MapGridPainter extends CustomPainter {
  final MapGrid mapGrid;
  final Map<String, Color> terrainColors;

  MapGridPainter({required this.mapGrid, required this.terrainColors});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / mapGrid.gridX;
    final cellHeight = size.height / mapGrid.gridY;

    for (int y = 0; y < mapGrid.gridY; y++) {
      for (int x = 0; x < mapGrid.gridX; x++) {
        final terrainChar = mapGrid.grid[y][x];
        final color = terrainColors[terrainChar] ?? terrainColors['']; // Default to transparent if not found

        final rect = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );

        final paint = Paint()..color = color ?? Colors.transparent;
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is MapGridPainter) {
      return oldDelegate.mapGrid != mapGrid || oldDelegate.terrainColors != terrainColors;
    }
    return true;
  }
}
