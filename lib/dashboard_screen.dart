import 'package:flutter/material.dart';
import 'WaterInside.dart';
import 'ProfileScreen.dart'; 
import 'CommunityPortalScreen.dart';
import 'DialysisTrackerScreen.dart'; // Ensure this import is included
import 'CommunityPortalDataUploader.dart'; // Ensure this import is included
import 'AwarenessProgramme.dart'; // <--- NEW IMPORT

// ... rest of the imports (ensure all imports you listed are present)

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary color from the UI image
    const Color primaryBlue = Color(0xFFE0F7FA); // Light blue background for the top section
    const Color darkBlueText = Color(0xFF006064); // Dark blue for NephroMind text
    const Color cardBackgroundLight = Color(0xFFF8F8F8); // A very light grey for card backgrounds
    const Color accentGreen = Color(0xFF81C784); // Green for "Start Check-up" button
    const Color accentOrange = Color(0xFFFFB74D); // Orange for "Risk Level"
    const Color accentPurple = Color(0xFF9C27B0); // Purple for "Community Portal" and profile icon
    const Color accentRed = Color(0xFFE57373); // Red for new upload button

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue, // Top section background color
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: darkBlueText),
            onPressed: () {
              // Scaffold.of(context).openDrawer(); // For a drawer
            },
          ),
        ),
        title: const Text(
          'NephroMind',
          style: TextStyle(
            color: darkBlueText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.wifi, color: Colors.transparent), // Placeholder for consistent spacing
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Top Section (Header and Self-Check Card)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              color: primaryBlue, // Background for the top section
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue, // Blue circle as in the image
                        // backgroundImage: AssetImage('assets/profile_pic.png'), // If you have a profile picture
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Hello, Mr. Silva',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: darkBlueText,
                            ),
                          ),
                          Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  // Self-Check Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Self-Check',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlueText,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'ML-Based Prediction',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed: () {
                                  // Handle Start Check-up
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentGreen, // Green button
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                ),
                                child: const Text(
                                  'Start Check-up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Placeholder for kidney image as in the original UI
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(Icons.healing, size: 40, color: darkBlueText),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Risk Level',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'MEDIUM',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: accentOrange, // Orange text
                                ),
                              ),
                              const Text(
                                'Based on\nrecent vitals.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main Grid Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15.0,
                mainAxisSpacing: 15.0,
                childAspectRatio: 1.1, // Adjust to make cards slightly taller
                children: <Widget>[
                  _DashboardCard(
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    title: 'Dialysis Tracker',
                    subtitle: 'Schedule\nAppointment',
                    buttonText: 'Schedule Appointment',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DialysisTrackerScreen()),
                      );
                    },
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  _DashboardCard(
                    icon: Icons.water_drop,
                    iconColor: Colors.lightBlue,
                    title: 'Water Intake',
                    subtitle: '1500 ml / 2000 ml',
                    progressValue: 0.75,
                    buttonText: 'Log Water',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WaterInsideScreen()),
                      );
                    },
                    showButton: true,
                    backgroundColor: const Color(0xFFF8F8F8),
                  ),
                  _DashboardCard(
                    icon: Icons.restaurant,
                    iconColor: Colors.green,
                    title: 'Food Helper',
                    subtitle: 'Kidney-Safe Recipes',
                    buttonText: 'Browse',
                    onTap: () {},
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  _DashboardCard(
                    icon: Icons.person_search,
                    iconColor: Colors.orange,
                    title: 'Doctor Suggestions',
                    subtitle: 'Find Specialists',
                    buttonText: 'Explore',
                    onTap: () {},
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  _DashboardCard(
                    icon: Icons.people,
                    iconColor: accentPurple,
                    title: 'Community Portal',
                    subtitle: 'Health Tips & More',
                    buttonText: 'Read Tips',
                    onTap: () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const CommunityPortalScreen()),
                       );
                    },
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  // Awareness Programs Card
                  _DashboardCard(
                    icon: Icons.campaign,
                    iconColor: Colors.redAccent,
                    title: 'Awareness Programs',
                    subtitle: 'Health Tips & More',
                    buttonText: 'View More',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AwarenessProgramme()),
                      );
                    },
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  // NEW: Community Portal Data Uploader Card
                  _DashboardCard(
                    icon: Icons.cloud_upload,
                    iconColor: accentRed,
                    title: 'Data Uploader',
                    subtitle: 'Upload Resources\n& Content',
                    buttonText: 'Upload Now',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CommunityPortalDataUploader()),
                      );
                    },
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Add some bottom spacing
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkBlueText,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        currentIndex: 0,
        onTap: (index) {
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
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

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.progressValue,
    this.showButton = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final double? progressValue;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: iconColor, size: 35),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (progressValue != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressValue!,
                  backgroundColor: Colors.grey[300],
                  color: iconColor,
                ),
              ],
              const SizedBox(height: 8),
              if (showButton && buttonText != null)
                Text(
                  buttonText!,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}