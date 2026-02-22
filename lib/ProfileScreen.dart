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
  static const Color primaryBlue = Color(0xFFE0F7FA);
  static const Color darkBlueText = Color(0xFF006064);
  static const Color accentBlue = Color(0xFF29B6F6);
  static const Color accentOrange = Color(0xFFFFB74D);
  static const Color accentRed = Color(0xFFEF5350);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color cardBackground = Colors.white;

  String? _fullName;
  String? _email;
  String? _diagnosisLabel;
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
      return;
    }

    try {
      // Fetch user info
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _fullName = userDoc.data()?['fullName'] ?? 'User';
        _email = _currentUser!.email;
      } else {
        _fullName = 'User';
        _email = _currentUser!.email;
      }

      // Fetch latest CKD result for this user
      final ckdQuery = await FirebaseFirestore.instance
          .collection('ckd_results')
          .where('userId', isEqualTo: _currentUser!.uid)
          .orderBy('checkedAt', descending: true)
          .limit(1)
          .get();

      if (ckdQuery.docs.isNotEmpty) {
        _diagnosisLabel = ckdQuery.docs.first.data()['diagnosisLabel'] ?? 'Unknown';
      } else {
        _diagnosisLabel = null; // No result found
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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

  Future<void> _updatePassword(String newPassword) async {
    try {
      await _currentUser!.updatePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
      }
    } on FirebaseAuthException catch (e) {
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

  Future<void> _handleLogOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

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

  /// Returns display label, color based on diagnosisLabel from Firestore
  Map<String, dynamic> _getStatusInfo(String? label) {
    if (label == null) {
      return {'text': 'No Data', 'color': Colors.grey};
    }
    switch (label.toLowerCase()) {
      case 'no ckd':
        return {'text': 'No CKD', 'color': accentGreen};
      case 'mild':
        return {'text': 'MILD', 'color': accentOrange};
      case 'moderate':
        return {'text': 'MODERATE', 'color': accentOrange};
      case 'severe':
      case 'ckd':
        return {'text': label.toUpperCase(), 'color': accentRed};
      default:
        return {'text': label, 'color': accentOrange};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: primaryBlue,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final displayFullName = _fullName ?? 'User';
    final firstName = displayFullName.split(' ').first;
    final statusInfo = _getStatusInfo(_diagnosisLabel);

    return Scaffold(
      backgroundColor: primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlueText),
          onPressed: () => Navigator.of(context).pop(),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                  'Hello, $firstName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: darkBlueText,
                  ),
                ),
                const Text(
                  'Welcome back!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
                    ),
                    _InfoField(
                      hint: 'Email',
                      value: _email ?? 'N/A',
                      icon: Icons.email,
                    ),
                    _InfoField(
                      hint: 'Password',
                      value: '********',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: _showEditProfileModal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accentBlue,
                          side: const BorderSide(color: accentBlue),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 30),
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
                              'Kidney Health Status:',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _diagnosisLabel != null
                                  ? statusInfo['text']
                                  : 'No Results Yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: statusInfo['color'],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _diagnosisLabel != null
                                  ? 'Based on your latest self-check'
                                  : 'Complete a self-check to see results',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        // Status icon badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (statusInfo['color'] as Color)
                                .withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _diagnosisLabel == null ||
                                    _diagnosisLabel!.toLowerCase() == 'no ckd'
                                ? Icons.favorite
                                : Icons.warning_amber_rounded,
                            color: statusInfo['color'],
                            size: 30,
                          ),
                        ),
                      ],
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
        onLogOut: _handleLogOut,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔥 Reusable Sub-Widgets
// -----------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ProfileCard({required this.title, required this.children});
  static const Color darkBlueText = Color(0xFF006064);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
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
  final String value;
  final IconData icon;
  final bool isPassword;

  const _InfoField({
    required this.hint,
    required this.value,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: TextEditingController(text: value),
        readOnly: true,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon, color: _ProfileScreenState.darkBlueText),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ProfileBottomNavBar extends StatelessWidget {
  final Color accentBlue;
  final VoidCallback onLogOut;

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
              icon: Icons.check_circle_outline,
              label: 'Self-Check',
              isSelected: false),
          Container(
            height: 50,
            width: 100,
            decoration: BoxDecoration(
              color: accentBlue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: onLogOut,
              child: const Text(
                'Log Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _NavBarItem(
              icon: Icons.fastfood,
              label: 'Food',
              isSelected: false,
              notificationCount: 1),
          _NavBarItem(
              icon: Icons.person, label: 'Profile', isSelected: true),
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
    final color =
        isSelected ? _ProfileScreenState.darkBlueText : Colors.grey[600];

    return InkWell(
      onTap: () {
        // TODO: Handle navigation based on label
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
                      constraints: const BoxConstraints(
                          minWidth: 12, minHeight: 12),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔥 Edit Profile Modal
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

    if (newName != widget.currentName && newName.isNotEmpty) {
      await widget.onNameUpdate(newName);
    }

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
    if (mounted) Navigator.of(context).pop();
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: "Full Name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
              'Change Password (Leave blank to keep current password)'),
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
                      style:
                          TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}