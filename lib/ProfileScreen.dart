import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Define colors consistent with the application's theme
  static const Color primaryBlue = Color(0xFFE0F7FA); // Light blue background for the top section
  static const Color darkBlueText = Color(0xFF006064); // Dark blue for titles/accents
  static const Color accentBlue = Color(0xFF29B6F6); // Log Out/Update Vitals button color
  static const Color accentOrange = Color(0xFFFFB74D); // Orange for "MEDIUM" risk level
  static const Color cardBackground = Colors.white; // White card background

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBlue, // Base background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlueText),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: darkBlueText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background fade effect (optional, matching the UI style)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primaryBlue, Colors.white],
                stops: [0.3, 1.0],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // --- Profile Header ---
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: darkBlueText,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Hello, Mr. Silva',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkBlueText,
                  ),
                ),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // --- 1. Personal Information Card ---
                _ProfileCard(
                  title: 'Personal Information',
                  children: [
                    _InfoField(hint: 'Name', icon: Icons.person, hasDropdown: true),
                    _InfoField(hint: 'Email', icon: Icons.email),
                    _InfoField(hint: 'Password', icon: Icons.lock, isPassword: true, hasDropdown: true),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentBlue,
                          side: const BorderSide(color: accentBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- 2. Health Information Card ---
                _ProfileCard(
                  title: 'Health Information',
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kidney Health Status: ',
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                            Text(
                              'MEDIUM',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: accentOrange,
                              ),
                            ),
                            const Text(
                              'Update Vitals',
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Update Vitals', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- 3. Notification Settings Card ---
                _ProfileCard(
                  title: 'Notification Settings',
                  children: [
                    _NotificationTile(
                      label: 'Date Sor Borth',
                      subLabel: 'Kidney-Safe Recipes',
                      value: false, // Example default
                      onChanged: (bool value) {},
                      icon: Icons.person_outline,
                    ),
                    const Divider(height: 20),
                    _NotificationTile(
                      label: 'Daily Reminders',
                      subLabel: 'Height',
                      value: true, // Example default
                      onChanged: (bool value) {},
                      icon: Icons.access_time,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- 4. App Settings and Apt Sections ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProfileCard(
                        title: 'App Settings',
                        children: [
                          _SmallSettingItem(label: 'Daily Reminders Alerts'),
                          _SmallSettingItem(label: 'Language'),
                          _SmallSettingItem(label: 'Privacy Policy'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _ProfileCard(
                        title: 'Apt Sections',
                        children: [
                          _ToggleSettingItem(label: 'Appointment', value: true, onChanged: (v){}),
                          _SmallSettingItem(label: 'Privacy Policy'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ProfileBottomNavBar(accentBlue: accentBlue),
    );
  }
}

// --- Reusable Sub-Widgets ---

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ProfileScreen.cardBackground,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ProfileScreen.darkBlueText,
            ),
          ),
          const Divider(height: 25, thickness: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool hasDropdown;

  const _InfoField({
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.hasDropdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: hasDropdown ? const Icon(Icons.keyboard_arrow_down) : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const _NotificationTile({
    required this.label,
    required this.subLabel,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: ProfileScreen.darkBlueText),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subLabel, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ProfileScreen.accentBlue,
        ),
      ],
    );
  }
}

class _SmallSettingItem extends StatelessWidget {
  final String label;

  const _SmallSettingItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        label,
        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
      ),
    );
  }
}

class _ToggleSettingItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSettingItem({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ProfileScreen.accentBlue,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _ProfileBottomNavBar extends StatelessWidget {
  final Color accentBlue;

  const _ProfileBottomNavBar({required this.accentBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(icon: Icons.home, label: 'Home', isSelected: false),
          _NavBarItem(icon: Icons.check_circle_outline, label: 'Self-Check', isSelected: false),
          // Custom Log Out Button
          Container(
            height: 50,
            width: 100,
            decoration: BoxDecoration(
              color: accentBlue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _NavBarItem(icon: Icons.fastfood, label: 'Food', isSelected: false, notificationCount: 1),
          _NavBarItem(icon: Icons.person, label: 'Profile', isSelected: true),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int notificationCount;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? ProfileScreen.darkBlueText : Colors.grey[600];

    return InkWell(
      onTap: () {
        // Handle navigation
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(icon, color: color, size: 26),
                if (notificationCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}