import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDate;
  bool _loading = false;

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ✅ Brevo Welcome Email
  Future<void> _sendWelcomeEmail(String email, String fullName) async {
   
final String brevoApiKey = dotenv.env['BREVO_API_KEY'] ?? '';
    const String senderEmail = 'nephromindsafehealth@gmail.com';
    const String senderName = 'NephroMind';

    try {
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'api-key': brevoApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sender': {'name': senderName, 'email': senderEmail},
          'to': [
            {'email': email, 'name': fullName}
          ],
          'subject': 'Welcome to NephroMind! 🎉',
          'htmlContent': '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto;">
              <div style="background-color: #006064; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
                <h1 style="color: white; margin: 0;">Welcome to NephroMind</h1>
                <p style="color: #B2EBF2; margin-top: 8px;">Kidney Health Management</p>
              </div>
              <div style="background-color: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">
                <h2 style="color: #006064;">Hello, $fullName! 👋</h2>
                <p style="color: #555; font-size: 16px;">
                  Thank you for joining <strong>NephroMind</strong>.
                  We are here to help you monitor and manage your kidney health every day.
                </p>
                <p style="color: #555; font-size: 16px;">Here is what you can do with NephroMind:</p>
                <ul style="color: #555; font-size: 15px; line-height: 2;">
                  <li>✅ Complete your kidney self-check</li>
                  <li>🍽️ Explore kidney-safe recipes</li>
                  <li>📅 Track your dialysis appointments</li>
                  <li>💧 Monitor your daily water intake</li>
                  <li>📊 View your kidney health history</li>
                </ul>
                <div style="background-color: #E0F7FA; padding: 15px; border-radius: 8px; margin: 20px 0;">
                  <p style="color: #006064; margin: 0; font-size: 14px;">
                    💡 <strong>Tip:</strong> Start by completing your first kidney self-check
                    to get your personalized health status.
                  </p>
                </div>
                <p style="color: #999; font-size: 13px; text-align: center; margin-top: 30px;">
                  If you did not create this account, please ignore this email.<br/>
                  © 2026 NephroMind. All rights reserved.
                </p>
              </div>
            </div>
          ''',
        }),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Welcome email sent to $email');
      } else {
        debugPrint('❌ Email failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Email failure will not block registration
      debugPrint('❌ Email error: $e');
    }
  }

  /// 🔥 REGISTER AND SAVE TO FIRESTORE
  Future<void> _handleRegistration() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your date of birth.")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // 1️⃣ Create user in Firebase Authentication
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 2️⃣ Save additional data in Firestore
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "fullName": fullName,
        "email": email,
        "dob": DateFormat('yyyy-MM-dd').format(_selectedDate!),
        "createdAt": Timestamp.now(),
      });

      // 3️⃣ Send welcome email via Brevo
      await _sendWelcomeEmail(email, fullName);

      // 4️⃣ Navigate to dashboard
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Registration failed")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                  labelText: "Full Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            /// DOB
            TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: _selectedDate == null
                    ? ""
                    : DateFormat("MM/dd/yyyy").format(_selectedDate!),
              ),
              decoration: const InputDecoration(
                labelText: "Date of Birth",
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleRegistration,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Register Account"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
