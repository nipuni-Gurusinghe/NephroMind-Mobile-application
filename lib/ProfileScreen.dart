import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// -----------------------------------------------------------------------------
// 🔥 Main Profile Screen Widget
// -----------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Define colors consistent with the application's theme
  static const Color primaryBlue = Color(0xFFE0F7FA); // Light blue background
  static const Color darkBlueText = Color(0xFF006064); // Dark blue for titles/accents
  static const Color accentBlue = Color(0xFF29B6F6); // Log Out/Update Vitals button color
  static const Color accentOrange = Color(0xFFFFB74D); // Orange for "MEDIUM" risk level
  static const Color cardBackground = Colors.white; // White card background

  String? _fullName;
  String? _email;
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Function to fetch user data from Firebase Auth and Firestore
  Future<void> _fetchUserProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      // User is not logged in, navigate to welcome/login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _fullName = userDoc.data()?['fullName'] ?? 'User';
          _email = _currentUser!.email;
        });
      } else {
        setState(() {
          _fullName = 'User';
          _email = _currentUser!.email;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to handle name update
  Future<void> _updateName(String newName) async {
    if (_currentUser == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'fullName': newName});
      setState(() {
        _fullName = newName;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully!')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $e')),
        );
      }
    }
  }

  // Function to handle password update
  Future<void> _updatePassword(String newPassword) async {
    try {
      await _currentUser!.updatePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle re-authentication if required for security
      if (e.code == 'requires-recent-login') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Re-login required to update password. Please log out and back in.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update password: ${e.message}')),
          );
        }
      }
    } on Exception catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  // Function to handle Log Out
  Future<void> _handleLogOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Navigate to the welcome screen and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // Function to show the edit profile modal
  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _EditProfileModal(
            currentName: _fullName ?? 'User',
            onNameUpdate: _updateName,
            onPasswordUpdate: _updatePassword,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: primaryBlue,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine the name to display (handle null safety)
    final displayFullName = _fullName ?? 'User';
    final firstName = displayFullName.split(' ').first;

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
          // Background fade effect
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
                Text(
                  'Hello, $firstName', // Display first name for a friendly greeting
                  style: const TextStyle(
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
                    _InfoField(
                      hint: 'Name',
                      value: displayFullName,
                      icon: Icons.person,
                      isReadOnly: true, // Display only
                    ),
                    _InfoField(
                      hint: 'Email',
                      value: _email ?? 'N/A',
                      icon: Icons.email,
                      isReadOnly: true, // Email usually cannot be changed easily
                    ),
                    _InfoField(
                      hint: 'Password',
                      value: '********',
                      icon: Icons.lock,
                      isPassword: true,
                      isReadOnly: true,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: _showEditProfileModal, // Show edit modal
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentBlue,
                          side: const BorderSide(color: accentBlue),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- 2. Health Information Card (Existing Code) ---
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
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700]),
                            ),
                            const Text(
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
                          onPressed: () {
                            // TODO: Implement navigation to Vitals Update screen
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Update Vitals',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- 3. Notification Settings Card (Existing Code) ---
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

                // --- 4. App Settings and Apt Sections (Existing Code) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProfileCard(
                        title: 'App Settings',
                        children: const [
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
                          _ToggleSettingItem(
                              label: 'Appointment', value: true, onChanged: (v) {}),
                          const _SmallSettingItem(label: 'Privacy Policy'),
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
      bottomNavigationBar: _ProfileBottomNavBar(
        accentBlue: accentBlue,
        onLogOut: _handleLogOut, // Pass the log out function
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔥 Reusable Sub-Widgets (Updated)
// -----------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ProfileCard({required this.title, required this.children});
  static const Color darkBlueText = Color(0xFF006064);
  static const Color cardBackground = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardBackground,
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
              color: darkBlueText,
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
  final String value; // New: holds the actual data value
  final IconData icon;
  final bool isPassword;
  final bool isReadOnly; // New: determines if it's display-only

  const _InfoField({
    required this.hint,
    required this.value,
    required this.icon,
    this.isPassword = false,
    this.isReadOnly = false, // Default to editable/display for now
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: TextEditingController(text: value), // Use controller to set value
        readOnly: isReadOnly, // Make it display-only
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: hint, // Use labelText for better look with a fixed value
          prefixIcon: Icon(icon, color: _ProfileScreenState.darkBlueText),
          filled: true,
          fillColor: isReadOnly ? Colors.grey[100] : Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontWeight: FontWeight.w500),
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
        Icon(icon, color: _ProfileScreenState.darkBlueText),
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
          activeColor: _ProfileScreenState.accentBlue,
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

  const _ToggleSettingItem(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _ProfileScreenState.accentBlue,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _ProfileBottomNavBar extends StatelessWidget {
  final Color accentBlue;
  final VoidCallback onLogOut; // New: Log out function

  const _ProfileBottomNavBar(
      {required this.accentBlue, required this.onLogOut});

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
          _NavBarItem(
              icon: Icons.check_circle_outline, label: 'Self-Check', isSelected: false),
          // Custom Log Out Button
          Container(
            height: 50,
            width: 100,
            decoration: BoxDecoration(
              color: accentBlue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: onLogOut, // Call the passed log out function
              child: const Text(
                'Log Out',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _NavBarItem(
              icon: Icons.fastfood,
              label: 'Food',
              isSelected: false,
              notificationCount: 1),
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
    final color = isSelected ? _ProfileScreenState.darkBlueText : Colors.grey[600];

    return InkWell(
      onTap: () {
        // TODO: Handle navigation based on the label
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

// -----------------------------------------------------------------------------
// 🔥 Edit Profile Modal (New Widget)
// -----------------------------------------------------------------------------

class _EditProfileModal extends StatefulWidget {
  final String currentName;
  final Function(String) onNameUpdate;
  final Function(String) onPasswordUpdate;

  const _EditProfileModal({
    required this.currentName,
    required this.onNameUpdate,
    required this.onPasswordUpdate,
  });

  @override
  __EditProfileModalState createState() => __EditProfileModalState();
}

class __EditProfileModalState extends State<_EditProfileModal> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);

    final newName = _nameController.text.trim();
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Update Name (if changed)
    if (newName != widget.currentName && newName.isNotEmpty) {
      await widget.onNameUpdate(newName);
    }

    // 2. Update Password (if provided)
    if (newPassword.isNotEmpty) {
      if (newPassword != confirmPassword) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("New passwords do not match!")),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else if (newPassword.length < 6) {
        // Basic length check
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Password must be at least 6 characters.")),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else {
        await widget.onPasswordUpdate(newPassword);
      }
    }

    setState(() => _isLoading = false);
    if (mounted) {
      Navigator.of(context).pop(); // Close modal after successful update(s)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _ProfileScreenState.darkBlueText,
            ),
          ),
          const Divider(height: 30),
          // --- Name Field ---
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          // --- Password Fields ---
          const Text('Change Password (Leave blank to keep current password)'),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "New Password",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Confirm New Password",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_reset),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ProfileScreenState.accentBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save Changes",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}