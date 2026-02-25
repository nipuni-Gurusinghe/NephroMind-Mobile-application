import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Removed hardcoded hospital list — now fetched from Firestore 'hospitals' collection

const List<String> routineTimeSlots = [
  '06:00-09:00',
  '10:00-13:00',
  '14:00-17:00',
  '18:00-21:00',
];

const String emergencyTimeSlot = '22:00-01:00 (Emergency)';

class DialysisTrackerScreen extends StatefulWidget {
  const DialysisTrackerScreen({super.key});

  @override
  State<DialysisTrackerScreen> createState() => _DialysisTrackerScreenState();
}

class _DialysisTrackerScreenState extends State<DialysisTrackerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _selectedHospital;
  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _hospitals = [];
  bool _loadingHospitals = true;

  String get currentPatientId {
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest_uid';
  }

  String get currentUserEmail {
    return FirebaseAuth.instance.currentUser?.email ?? '';
  }

  late final String formattedToday =
      DateFormat('yyyy-MM-dd').format(DateUtils.dateOnly(DateTime.now()));

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _fetchHospitals();
  }

  // --- FETCH HOSPITALS FROM FIRESTORE ---

  Future<void> _fetchHospitals() async {
    try {
      final snapshot = await _firestore
          .collection('hospitals')
          .where('isActive', isEqualTo: true)
          .get();

      final List<Map<String, dynamic>> fetchedHospitals = snapshot.docs
          .map((doc) => {
                'docId': doc.id,
                'name': doc['name'] as String? ?? 'Unknown Hospital',
                'dialysisBeds': doc['dialysisBeds'] as int? ?? 0,
                'dialysisSlots': List<String>.from(
                    doc['dialysisSlots'] as List? ?? routineTimeSlots),
              })
          .toList();

      if (mounted) {
        setState(() {
          _hospitals = fetchedHospitals;
          _selectedHospital =
              fetchedHospitals.isNotEmpty ? fetchedHospitals.first : null;
          _loadingHospitals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingHospitals = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hospitals: $e')),
        );
      }
    }
  }

  // --- HELPER FUNCTIONS ---

  List<DateTime> _getDateRange() {
    final List<DateTime> dates = [];
    final now = DateUtils.dateOnly(DateTime.now());
    for (int i = 0; i < 7; i++) {
      dates.add(now.add(Duration(days: i)));
    }
    return dates;
  }

  List<String> _getHospitalSlots() {
    if (_selectedHospital == null) return [...routineTimeSlots];
    return List<String>.from(
        _selectedHospital!['dialysisSlots'] ?? routineTimeSlots);
  }

  List<String> _getAvailableTimeSlots(DateTime date) {
    final List<String> slots = _getHospitalSlots();

    if (DateUtils.isSameDay(date, DateTime.now())) {
      final now = DateTime.now();
      slots.retainWhere((slot) {
        final startTimeStr = slot.split('-').first;
        final parts = startTimeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final slotStartTime =
            DateTime(now.year, now.month, now.day, hour, minute);
        return slotStartTime.isAfter(now);
      });
    }
    return slots;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF006064),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF006064),
              onPrimary: Colors.white,
            ),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && !DateUtils.isSameDay(picked, _selectedDate)) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(picked);
      });
    }
  }

  // --- BREVO APPOINTMENT CONFIRMATION EMAIL ---

  Future<void> _sendAppointmentConfirmationEmail({
    required String toEmail,
    required String patientName,
    required String hospitalName,
    required String date,
    required String timeSlot,
    required int bedNumber,
  }) async {
    final String brevoApiKey = dotenv.env['BREVO_API_KEY'] ?? '';
    const String senderEmail = 'nephromindsafehealth@gmail.com';
    const String senderName = 'NephroMind';

    // Format date nicely for display e.g. "25 February 2026"
    final formattedDisplayDate = DateFormat('dd MMMM yyyy')
        .format(DateFormat('yyyy-MM-dd').parse(date));

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
            {'email': toEmail, 'name': patientName}
          ],
          'subject': '✅ Dialysis Appointment Confirmed – NephroMind',
          'htmlContent': '''
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto;">

              <!-- Header -->
              <div style="background-color: #006064; padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
                <h1 style="color: white; margin: 0;">NephroMind</h1>
                <p style="color: #B2EBF2; margin-top: 8px;">Dialysis Appointment Confirmation</p>
              </div>

              <!-- Body -->
              <div style="background-color: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px;">

                <h2 style="color: #006064;">Hello, $patientName! 👋</h2>
                <p style="color: #555; font-size: 16px;">
                  Your dialysis appointment has been
                  <strong style="color: #2E7D32;">successfully confirmed</strong>.
                  Please find your appointment details below.
                </p>

                <!-- Appointment Details Box -->
                <div style="background-color: #E0F7FA; border-left: 5px solid #006064;
                            padding: 20px; border-radius: 8px; margin: 24px 0;">
                  <h3 style="color: #006064; margin-top: 0;">📋 Appointment Details</h3>
                  <table style="width: 100%; font-size: 15px; color: #333; border-collapse: collapse;">
                    <tr>
                      <td style="padding: 8px 0; font-weight: bold; width: 40%;">🏥 Hospital</td>
                      <td style="padding: 8px 0;">$hospitalName</td>
                    </tr>
                    <tr style="background-color: #f0fbfc;">
                      <td style="padding: 8px 0; font-weight: bold;">📅 Date</td>
                      <td style="padding: 8px 0;">$formattedDisplayDate</td>
                    </tr>
                    <tr>
                      <td style="padding: 8px 0; font-weight: bold;">⏰ Time Slot</td>
                      <td style="padding: 8px 0;">$timeSlot</td>
                    </tr>
                    <tr style="background-color: #f0fbfc;">
                      <td style="padding: 8px 0; font-weight: bold;">🛏️ Bed Number</td>
                      <td style="padding: 8px 0;"><strong>#$bedNumber</strong></td>
                    </tr>
                  </table>
                </div>

                <!-- Reminder Box -->
                <div style="background-color: #FFF8E1; border-left: 5px solid #F9A825;
                            padding: 16px; border-radius: 8px; margin-bottom: 24px;">
                  <p style="color: #7B5800; margin: 0; font-size: 14px;">
                    ⚠️ <strong>Reminder:</strong> Please arrive at least
                    <strong>15 minutes</strong> before your scheduled time slot.
                    Bring your NIC and any previous medical records.
                  </p>
                </div>

                <!-- Cancel Note -->
                <p style="color: #555; font-size: 14px;">
                  If you need to cancel or reschedule, please do so through the
                  <strong>NephroMind app</strong> as soon as possible so the bed
                  can be made available to another patient.
                </p>

                <!-- Footer -->
                <p style="color: #999; font-size: 13px; text-align: center; margin-top: 30px;">
                  This is an automated confirmation from NephroMind.<br/>
                  If you did not make this booking, please contact us immediately.<br/><br/>
                  © 2026 NephroMind. All rights reserved.
                </p>

              </div>
            </div>
          ''',
        }),
      );

      if (response.statusCode == 201) {
        debugPrint('✅ Confirmation email sent to $toEmail');
      } else {
        debugPrint(
            '❌ Email failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Email failure will NOT block or crash the booking flow
      debugPrint('❌ Email error: $e');
    }
  }

  // --- FIREBASE INTERACTIONS ---

  Stream<QuerySnapshot> _fetchBookedAppointments() {
    if (_selectedHospital == null) return const Stream.empty();
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return _firestore
        .collection('dialysis_appointments')
        .where('hospitalId', isEqualTo: _selectedHospital!['docId'])
        .where('date', isEqualTo: formattedDate)
        .where('type', isEqualTo: 'routine')
        .snapshots();
  }

  Stream<QuerySnapshot> _fetchUserAppointments() {
    return _firestore
        .collection('dialysis_appointments')
        .where('patientId', isEqualTo: currentPatientId)
        .where('date', isGreaterThanOrEqualTo: formattedToday)
        .orderBy('date')
        .orderBy('timeSlot')
        .snapshots();
  }

  Future<void> _confirmAndBookAppointment(
      BuildContext context, String timeSlot, int bedsRemaining) async {
    if (_selectedHospital == null) return;

    final hospitalName = _selectedHospital!['name'];
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Appointment'),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 16),
            children: <TextSpan>[
              const TextSpan(
                  text: 'Are you sure you want to book this appointment?\n\n'),
              const TextSpan(
                  text: 'Hospital: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$hospitalName\n'),
              const TextSpan(
                  text: 'Date: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$formattedDate\n'),
              const TextSpan(
                  text: 'Time: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$timeSlot\n'),
              const TextSpan(
                  text: 'Beds Remaining: ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$bedsRemaining'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bookAppointment(timeSlot);
    } else if (confirmed == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booking cancelled.')),
        );
      }
    }
  }

  Future<void> _bookAppointment(String timeSlot) async {
    if (_selectedHospital == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final hospitalId = _selectedHospital!['docId'];
    final totalBeds = _selectedHospital!['dialysisBeds'] as int;

    try {
      // Double-check bed availability (race condition safety)
      final existingBookings = await _firestore
          .collection('dialysis_appointments')
          .where('hospitalId', isEqualTo: hospitalId)
          .where('date', isEqualTo: formattedDate)
          .where('timeSlot', isEqualTo: timeSlot)
          .where('type', isEqualTo: 'routine')
          .get();

      if (existingBookings.docs.length >= totalBeds) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Sorry, this slot just became fully booked. Please choose another.')),
          );
        }
        return;
      }

      // Assign next available bed number
      final bookedBedNumbers = existingBookings.docs
          .map((doc) => doc['bedNumber'] as int? ?? 0)
          .toSet();
      int assignedBed = 1;
      while (bookedBedNumbers.contains(assignedBed)) {
        assignedBed++;
      }

      // Save appointment to Firestore
      await _firestore.collection('dialysis_appointments').add({
        'hospitalId': hospitalId,
        'hospitalName': _selectedHospital!['name'],
        'date': formattedDate,
        'timeSlot': timeSlot,
        'bedNumber': assignedBed,
        'patientId': currentPatientId,
        'isBooked': true,
        'type': 'routine',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Fetch patient's full name from Firestore users collection
      String patientName = 'Patient';
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentPatientId)
            .get();
        if (userDoc.exists) {
          patientName =
              userDoc.data()?['fullName'] as String? ?? 'Patient';
        }
      } catch (_) {
        // fallback to 'Patient' if name fetch fails — won't block booking
      }

      // Send confirmation email via Brevo (same pattern as welcome email)
      if (currentUserEmail.isNotEmpty) {
        await _sendAppointmentConfirmationEmail(
          toEmail: currentUserEmail,
          patientName: patientName,
          hospitalName: _selectedHospital!['name'],
          date: formattedDate,
          timeSlot: timeSlot,
          bedNumber: assignedBed,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Appointment booked! Bed #$assignedBed on $formattedDate at $timeSlot. A confirmation email has been sent.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error booking appointment: ${e.message}. Are you logged in?')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e')),
        );
      }
    }
  }

  Future<void> _deleteAppointment(String appointmentDocId) async {
    try {
      await _firestore
          .collection('dialysis_appointments')
          .doc(appointmentDocId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment successfully deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting appointment: $e')),
        );
      }
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialysis Tracker'),
        backgroundColor: const Color(0xFFE0F7FA),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF006064)),
            onPressed: () => _selectDate(context),
            tooltip: 'Select Date',
          ),
        ],
      ),
      body: _loadingHospitals
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHospitalDropdown(),
                  const SizedBox(height: 20),
                  _buildDateSelector(),
                  const SizedBox(height: 20),
                  const Divider(),
                  Text(
                    'Dialysis Slots for ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedHospital != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        'Total beds available: ${_selectedHospital!['dialysisBeds']}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _buildAvailableSlots(),
                  const SizedBox(height: 30),
                  const Text(
                    'Your Booked Appointments',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006064)),
                  ),
                  _buildUserAppointments(),
                ],
              ),
            ),
    );
  }

  Widget _buildHospitalDropdown() {
    if (_hospitals.isEmpty) {
      return const Text('No active hospitals found.',
          style: TextStyle(color: Colors.red));
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      decoration: const InputDecoration(
        labelText: 'Select Hospital',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.local_hospital),
      ),
      value: _selectedHospital,
      isExpanded: true,
      items: _hospitals.map((hospital) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: hospital,
          child: Text(hospital['name'] as String),
        );
      }).toList(),
      onChanged: (Map<String, dynamic>? newValue) {
        setState(() {
          _selectedHospital = newValue;
        });
      },
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _getDateRange().map((date) {
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF006064)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                        color:
                            isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                        fontSize: 20,
                        color:
                            isSelected ? Colors.white : Colors.black),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailableSlots() {
    final availableSlots = _getAvailableTimeSlots(_selectedDate);
    final totalBeds = _selectedHospital?['dialysisBeds'] as int? ?? 0;

    return StreamBuilder<QuerySnapshot>(
      stream: _fetchBookedAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final Map<String, int> slotBookingCount = {};
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final slot = data['timeSlot'] as String? ?? '';
          slotBookingCount[slot] = (slotBookingCount[slot] ?? 0) + 1;
        }

        if (availableSlots.isEmpty) {
          return const Text('No more slots available today.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: availableSlots.length,
          itemBuilder: (context, index) {
            final slot = availableSlots[index];
            final bookedCount = slotBookingCount[slot] ?? 0;
            final bedsRemaining = totalBeds - bookedCount;
            final isFull = bedsRemaining <= 0;
            final timeParts = slot.split('-');

            Color cardColor;
            Color borderColor;
            Color textColor;
            if (isFull) {
              cardColor = Colors.red.shade100;
              borderColor = Colors.red;
              textColor = Colors.red.shade800;
            } else if (bedsRemaining <= 3) {
              cardColor = Colors.orange.shade100;
              borderColor = Colors.orange;
              textColor = Colors.orange.shade900;
            } else {
              cardColor = Colors.green.shade100;
              borderColor = Colors.green;
              textColor = Colors.green.shade800;
            }

            return InkWell(
              onTap: isFull
                  ? null
                  : () => _confirmAndBookAppointment(
                      context, slot, bedsRemaining),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${timeParts[0]} - ${timeParts[1]}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFull
                          ? 'FULL'
                          : '$bedsRemaining / $totalBeds beds free',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserAppointments() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchUserAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '❌ Error loading appointments. Ensure you are logged in and the required Firebase Composite Index exists.',
              style: TextStyle(color: Colors.red.shade800),
            ),
          );
        }

        final userAppointments = snapshot.data!.docs;

        if (userAppointments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('You have no upcoming appointments booked.',
                style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: userAppointments.length,
          itemBuilder: (context, index) {
            final doc = userAppointments[index];
            final data = doc.data() as Map<String, dynamic>;
            final isRoutine = data['type'] == 'routine';
            final bedNumber = data['bedNumber'] as int?;

            return Card(
              color: isRoutine
                  ? Colors.lightBlue.shade50
                  : Colors.deepOrange.shade50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  isRoutine ? Icons.bed : Icons.warning_amber_rounded,
                  color: isRoutine ? Colors.blue : Colors.deepOrange,
                ),
                title: Text(data['hospitalName'],
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${data['date']} at ${data['timeSlot']}'
                  '${bedNumber != null ? ' · Bed #$bedNumber' : ''}'
                  ' (${data['type'].toString().toUpperCase()})',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever,
                      color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Appointment'),
                        content: const Text(
                            'Are you sure you want to delete this appointment?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteAppointment(doc.id);
                            },
                            child: const Text('Delete',
                                style:
                                    TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
