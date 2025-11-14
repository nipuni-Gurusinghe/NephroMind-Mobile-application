import 'package:flutter/material.dart';

class WaterInsideScreen extends StatelessWidget {
  const WaterInsideScreen({super.key});

  // Define colors consistent with DashboardScreen
  static const Color primaryBlue = Color(0xFFE0F7FA); // Light blue background for the top section
  static const Color darkBlueText = Color(0xFF006064); // Dark blue text/icon color
  static const Color lightBlueBackground = Color(0xFFB3E5FC); // Lighter background color for water area
  static const Color accentWaterBlue = Color(0xFF4FC3F7); // Water fill color
  static const Color accentButtonBlue = Color(0xFF29B6F6); // Button background color
  static const Color cardBackgroundLight = Color(0xFFF8F8F8); // A very light grey for card backgrounds

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsiveness
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryBlue, // Match the primary color from the dashboard
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to blend with the body background
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlueText),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back
          },
        ),
        title: const Text(
          'Water Intake Tracker',
          style: TextStyle(
            color: darkBlueText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // --- Water Consumption Visualization Section ---
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 20, bottom: 40),
              color: primaryBlue,
              child: Column(
                children: [
                  // Kidney icon (Optional, for the app name)
                  const Icon(Icons.water_drop, color: darkBlueText, size: 50),
                  const SizedBox(height: 30),
                  // Water Drop Image Placeholder
                  const Icon(Icons.water_drop, color: accentWaterBlue, size: 80),
                  const SizedBox(height: 10),
                  // Water Glass / Goal Visualization
                  SizedBox(
                    width: size.width * 0.5, // Responsive width
                    child: AspectRatio(
                      aspectRatio: 0.8,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Base Glass Outline
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: darkBlueText.withOpacity(0.5), width: 3),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(5)),
                              color: Colors.transparent,
                            ),
                          ),
                          // Water Fill (75% full for 1500/2000)
                          FractionallySizedBox(
                            heightFactor: 0.75, // 1500 / 2000 = 0.75
                            child: Container(
                              decoration: BoxDecoration(
                                color: accentWaterBlue.withOpacity(0.8),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                              ),
                            ),
                          ),
                          // Current / Goal Text Overlay
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    '1500 ml',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Current / 2000 ml Goal',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Quick Add Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Add',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlueText,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                    _QuickAddButton(amount: 200, icon: Icons.local_cafe, backgroundColor: accentWaterBlue.withOpacity(0.1)),
                    _QuickAddButton(amount: 500, icon: Icons.local_cafe, backgroundColor: accentWaterBlue.withOpacity(0.1)),
                    _QuickAddButton(amount: 1000, icon: Icons.water_drop, backgroundColor: accentWaterBlue.withOpacity(0.1)),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- Manual Entry Section ---
                  const Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlueText,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter amount (ml)',
                            prefixIcon: Icon(Icons.sentiment_dissatisfied, color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: cardBackgroundLight,
                            contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          // Handle Log button tap
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentButtonBlue, // Blue Log button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                        ),
                        child: const Text(
                          'Log',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // --- Daily Water Consumption Chart ---
                  const Text(
                    'Daily Water Consumption',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkBlueText,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.5, // Adjust chart aspect ratio
                      child: _BarChart(accentWaterBlue: accentWaterBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // The bottom navigation bar is present but the 'Home' tab is active
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkBlueText,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        currentIndex: 0, // 'Home' is the current view's root navigation
        onTap: (index) {
          // Handle navigation here
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Self-Check',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Reusable Widget for Quick Add Buttons
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.amount,
    required this.icon,
    required this.backgroundColor,
  });

  final int amount;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            // Handle quick add log
          },
          child: Container(
            width: 80, // Fixed size for quick add buttons
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(color: WaterInsideScreen.accentWaterBlue, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: WaterInsideScreen.darkBlueText, size: 30),
                  Text(
                    '+$amount ml',
                    style: const TextStyle(
                      color: WaterInsideScreen.darkBlueText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Simple Placeholder for the Daily Water Consumption Bar Chart
class _BarChart extends StatelessWidget {
  const _BarChart({required this.accentWaterBlue});

  final Color accentWaterBlue;

  @override
  Widget build(BuildContext context) {
    // Sample data for the chart (0 to 8 units)
    final List<double> chartData = [2, 3, 5, 7, 8, 7, 5, 8];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y-axis labels
        ...List.generate(5, (index) => 8 - index * 2).map((label) => Text(
              label == 8 ? '8' : (label == 0 ? '0' : '$label'),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )).toList().reversed, // Reverse to show 0 at bottom, 8 at top
        const Spacer(),
        // Bar Chart
        Expanded(
          flex: 8,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: chartData.asMap().entries.map((entry) {
                int index = entry.key;
                double value = entry.value;

                // Max height for normalization is 8 (from the Y-axis)
                double normalizedHeight = value / 8.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: normalizedHeight * 150, // Arbitrary height scaling for visual size
                      width: 25,
                      decoration: BoxDecoration(
                        color: accentWaterBlue,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${index + 1}', // X-axis label (1 to 8)
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}