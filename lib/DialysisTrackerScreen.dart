import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- DATA DEFINITIONS ---

const List<Map<String, String>> hospitals = [
  {'id': 'h_colombo_n', 'name': 'National Hospital of Sri Lanka (Colombo)'},
  {'id': 'h_nindt', 'name': 'National Institute for Nephrology, Dialysis & Transplantation (NINDT)'},
  {'id': 'h_karapitiya', 'name': 'Karapitiya Teaching Hospital (Galle National Hospital)'},
  {'id': 'h_wellawaya', 'name': 'Wellawaya Base Hospital (Monaragala District)'},
  {'id': 'h_mullariyawa', 'name': 'Colombo East Base Hospital, Mullariyawa'},
];

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
  Map<String, String>? _selectedHospital;
  DateTime _selectedDate = DateTime.now();

  String get currentPatientId {
    // This is the correct way to filter by the current user.
    // Ensure the user is logged in for proper permissions.
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest_uid'; 
  }
  
  late final String formattedToday = DateFormat('yyyy-MM-dd').format(DateUtils.dateOnly(DateTime.now()));

  @override
  void initState() {
    super.initState();
    _selectedHospital = hospitals.first;
    _selectedDate = DateUtils.dateOnly(DateTime.now());
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

  List<String> _getAvailableTimeSlots(DateTime date) {
    final List<String> slots = [...routineTimeSlots];
    
    if (DateUtils.isSameDay(date, DateTime.now())) {
      final now = DateTime.now();
      slots.retainWhere((slot) {
        final startTimeStr = slot.split('-').first;
        final parts = startTimeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final slotStartTime = DateTime(now.year, now.month, now.day, hour, minute);
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
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
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

  // --- FIREBASE INTERACTIONS ---

  Stream<QuerySnapshot> _fetchBookedAppointments() {
    if (_selectedHospital == null) {
      return const Stream.empty();
    }
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    
    return _firestore
        .collection('dialysis_appointments')
        .where('hospitalId', isEqualTo: _selectedHospital!['id'])
        .where('date', isEqualTo: formattedDate)
        .where('type', isEqualTo: 'routine') 
        .snapshots();
  }

  Stream<QuerySnapshot> _fetchUserAppointments() {
    // This is the correct query to filter appointments for the current user.
    // It REQUIRES the composite index (see step 2 below).
    return _firestore
          .collection('dialysis_appointments')
          .where('patientId', isEqualTo: currentPatientId)
          .where('date', isGreaterThanOrEqualTo: formattedToday) 
          .orderBy('date')
          .orderBy('timeSlot')
          .snapshots();
  }
  
  Future<void> _confirmAndBookAppointment(BuildContext context, String timeSlot) async {
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
              const TextSpan(text: 'Are you sure you want to book this appointment?\n\n'),
              const TextSpan(text: 'Hospital: ', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$hospitalName\n'),
              const TextSpan(text: 'Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: '$formattedDate\n'),
              const TextSpan(text: 'Time: ', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: timeSlot),
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
            child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final hospitalId = _selectedHospital!['id'];

    try {
      await _firestore.collection('dialysis_appointments').add({
        'hospitalId': hospitalId,
        'hospitalName': _selectedHospital!['name'],
        'date': formattedDate,
        'timeSlot': timeSlot,
        'patientId': currentPatientId, 
        'isBooked': true,
        'type': 'routine',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment booked for $formattedDate $timeSlot at ${_selectedHospital!['name']}!')),
        );
      }
    } on FirebaseException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: ${e.message}. Did you log in?')),
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
      await _firestore.collection('dialysis_appointments').doc(appointmentDocId).delete();
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
      body: SingleChildScrollView(
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
              'Routine Dialysis Slots for ${DateFormat('dd MMMM yyyy').format(_selectedDate)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildAvailableSlots(),

            const SizedBox(height: 30),

            const Text(
              'Your Booked Appointments',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF006064)),
            ),
            _buildUserAppointments(),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalDropdown() {
    return DropdownButtonFormField<Map<String, String>>(
      decoration: const InputDecoration(
        labelText: 'Select Hospital',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.local_hospital),
      ),
      value: _selectedHospital,
      isExpanded: true, // Fixes the overflow error
      items: hospitals.map((hospital) {
        return DropdownMenuItem<Map<String, String>>(
          value: hospital,
          child: Text(hospital['name']!),
        );
      }).toList(),
      onChanged: (Map<String, String>? newValue) {
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
                color: isSelected ? const Color(0xFF006064) : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(fontSize: 20, color: isSelected ? Colors.white : Colors.black),
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

    return StreamBuilder<QuerySnapshot>(
      stream: _fetchBookedAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final bookedSlots = snapshot.data!.docs.map((doc) => doc['timeSlot'] as String).toSet();
        
        if (availableSlots.isEmpty) {
          return const Text('No more routine slots available today.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: availableSlots.length,
          itemBuilder: (context, index) {
            final slot = availableSlots[index];
            final isBooked = bookedSlots.contains(slot);
            final timeParts = slot.split('-');

            return InkWell(
              onTap: isBooked ? null : () => _confirmAndBookAppointment(context, slot),
              child: Container(
                decoration: BoxDecoration(
                  color: isBooked ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isBooked ? Colors.red : Colors.green),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${timeParts[0]} - ${timeParts[1]}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isBooked ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                    Text(
                      isBooked ? 'BOOKED' : 'AVAILABLE',
                      style: TextStyle(
                        fontSize: 12,
                        color: isBooked ? Colors.red.shade800 : Colors.green.shade800,
                      ),
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
          return const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ));
        }
        if (snapshot.hasError) {
          // Display the error without the long index explanation.
          // The critical issue is the missing Firebase index.
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '❌ Error loading appointments. This is usually fixed by creating the required Firebase Composite Index or ensuring you are logged in.', 
              style: TextStyle(color: Colors.red.shade800),
            ),
          );
        }
        
        final userAppointments = snapshot.data!.docs;
        
        if (userAppointments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('You have no upcoming appointments booked.', style: TextStyle(color: Colors.grey)),
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
            
            return Card(
              color: isRoutine ? Colors.lightBlue.shade50 : Colors.deepOrange.shade50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  isRoutine ? Icons.access_time : Icons.warning_amber_rounded,
                  color: isRoutine ? Colors.blue : Colors.deepOrange,
                ),
                title: Text(data['hospitalName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${data['date']} at ${data['timeSlot']} (${data['type'].toString().toUpperCase()})'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Appointment'),
                        content: const Text('Are you sure you want to delete this appointment?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteAppointment(doc.id);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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