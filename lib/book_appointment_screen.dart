import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final List<String> hospitals = [
    "Colombo East Base Hospital Mulleriyawa",
    "National Hospital of Sri Lanka",
    "Wellawaya Base Hospital",
    "Karapitiya Teaching Hospital",
    "National Institute for Nephrology Dialysis & Transplantation (NINDT)",
  ];

  String? selectedHospital;
  DateTime selectedDate = DateTime.now();

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  // Today's date string for filtering upcoming appointments
  final String formattedToday =
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get currentPatientId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Book Appointment",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown(),
            const SizedBox(height: 20),
            _buildDatePicker(),
            const SizedBox(height: 20),
            const Divider(),
            const Text("Available Doctors",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildDoctorList(),

            // --- MY BOOKINGS SECTION ---
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "My Booked Appointments",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            const SizedBox(height: 10),
            _buildMyAppointments(),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: "Select Hospital",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.local_hospital, color: Colors.teal),
      ),
      isExpanded: true,
      value: selectedHospital,
      items: hospitals
          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
          .toList(),
      onChanged: (val) => setState(() => selectedHospital = val),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      tileColor: Colors.teal.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title:
          Text("Date: ${DateFormat('EEE, d MMM yyyy').format(selectedDate)}"),
      trailing: const Icon(Icons.calendar_month, color: Colors.teal),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2027),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
    );
  }

  Widget _buildDoctorList() {
    if (selectedHospital == null) {
      return const Center(child: Text("Please select a hospital above"));
    }

    final startOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
    final endOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_availability')
          .where('hospitalName', isEqualTo: selectedHospital)
          .where('isAvailable', isEqualTo: true)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Error: ${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "No doctors available on this date at the selected hospital.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final availabilityDoc = docs[index];
            final data = availabilityDoc.data() as Map<String, dynamic>;
            final doctorId = availabilityDoc.id;
            final doctorName =
                data['doctorName'] as String? ?? 'Unknown Doctor';
            final slots = data['slots'] as Map<String, dynamic>? ?? {};

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading:
                    const Icon(Icons.person, color: Colors.teal, size: 40),
                title: Text(doctorName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text(data['hospitalName'] as String? ?? selectedHospital!),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white),
                  onPressed: () =>
                      _showSlotSelection(doctorId, doctorName, slots),
                  child: const Text("View Slots"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MY BOOKED APPOINTMENTS SECTION ---

  Widget _buildMyAppointments() {
    if (currentPatientId.isEmpty) {
      return const Text("Please log in to see your appointments.",
          style: TextStyle(color: Colors.grey));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('book_appointment')
          .where('patientId', isEqualTo: currentPatientId)
          .where('date', isGreaterThanOrEqualTo: formattedToday)
          .orderBy('date')
          .orderBy('timeSlot')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ));
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '❌ Error loading appointments. Ensure the required Firestore Composite Index exists.',
              style: TextStyle(color: Colors.red.shade800),
            ),
          );
        }

        final appointments = snapshot.data!.docs;

        if (appointments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "You have no upcoming appointments booked.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final doc = appointments[index];
            final data = doc.data() as Map<String, dynamic>;
            final queueNumber = data['queueNumber'] as int?;
            final status = data['status'] as String? ?? 'upcoming';

            // Status color
            Color statusColor;
            IconData statusIcon;
            if (status == 'completed') {
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
            } else if (status == 'cancelled') {
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
            } else {
              statusColor = Colors.teal;
              statusIcon = Icons.access_time;
            }

            return Card(
              color: Colors.teal.shade50,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal.shade100),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Left icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 12),

                    // Middle info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['doctor_name'] as String? ?? 'Unknown Doctor',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data['hospital_name'] as String? ?? '',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          // Date & Time row
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 13, color: Colors.teal),
                              const SizedBox(width: 4),
                              Text(
                                data['date'] as String? ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.access_time,
                                  size: 13, color: Colors.teal),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  data['timeSlot'] as String? ?? '',
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (queueNumber != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.confirmation_number,
                                    size: 13, color: Colors.teal),
                                const SizedBox(width: 4),
                                Text(
                                  "Queue #$queueNumber",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Right delete button
                    if (status != 'completed')
                      IconButton(
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.red),
                        onPressed: () => _showDeleteDialog(doc.id),
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

  // --- DELETE APPOINTMENT ---

  void _showDeleteDialog(String appointmentDocId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content:
            const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAppointment(appointmentDocId);
            },
            child:
                const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppointment(String appointmentDocId) async {
    try {
      await FirebaseFirestore.instance
          .collection('book_appointment')
          .doc(appointmentDocId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment cancelled successfully.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel: $e")),
        );
      }
    }
  }

  // --- SLOT SELECTION BOTTOM SHEET ---

  void _showSlotSelection(
      String doctorId, String doctorName, Map<String, dynamic> slots) {
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No slots defined for this doctor.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('book_appointment')
              .where('doctor_id', isEqualTo: doctorId)
              .where('date', isEqualTo: formattedDate)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(20),
                child:
                    Text("Error loading slots. Check Firestore indexes."),
              ));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final Map<String, int> slotBookingCount = {};
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final slot = data['timeSlot'] as String? ?? '';
              slotBookingCount[slot] = (slotBookingCount[slot] ?? 0) + 1;
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    "Slots for $doctorName",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(selectedDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  ...slots.entries.map((entry) {
                    final slotName = entry.key;
                    final maxPatients = entry.value as int;
                    final bookedCount = slotBookingCount[slotName] ?? 0;
                    final remaining = maxPatients - bookedCount;
                    final isFull = remaining <= 0;

                    Color statusColor;
                    String statusText;
                    if (isFull) {
                      statusColor = Colors.red;
                      statusText = "FULL";
                    } else if (remaining <= 2) {
                      statusColor = Colors.orange;
                      statusText =
                          "$remaining spot${remaining == 1 ? '' : 's'} left";
                    } else {
                      statusColor = Colors.green;
                      statusText = "$remaining / $maxPatients available";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isFull
                            ? Colors.red.shade50
                            : remaining <= 2
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: ListTile(
                        title: Text(slotName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(statusText,
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600)),
                        trailing: isFull
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text("FULL",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _confirmBooking(
                                    doctorId,
                                    doctorName,
                                    slotName,
                                    formattedDate,
                                    bookedCount + 1),
                                child: const Text("Book"),
                              ),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- SAVE BOOKING TO FIRESTORE ---

  void _confirmBooking(
    String docId,
    String docName,
    String slot,
    String date,
    int queueNumber,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Please log in again")));
      return;
    }

    try {
      final existingBookings = await FirebaseFirestore.instance
          .collection('book_appointment')
          .where('doctor_id', isEqualTo: docId)
          .where('date', isEqualTo: date)
          .where('timeSlot', isEqualTo: slot)
          .get();

      final availabilityDoc = await FirebaseFirestore.instance
          .collection('doctor_availability')
          .doc(docId)
          .get();

      final slots =
          availabilityDoc.data()?['slots'] as Map<String, dynamic>? ?? {};
      final maxPatients = slots[slot] as int? ?? 0;

      if (existingBookings.docs.length >= maxPatients) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Sorry, this slot just became full. Please choose another.")),
          );
        }
        return;
      }

      final actualQueueNumber = existingBookings.docs.length + 1;

      await FirebaseFirestore.instance.collection('book_appointment').add({
        'doctor_id': docId,
        'doctor_name': docName,
        'hospital_name': selectedHospital,
        'timeSlot': slot,
        'date': date,
        'queueNumber': actualQueueNumber,
        'isBooked': true,
        'patientId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Appointment confirmed with $docName at $slot — Queue #$actualQueueNumber")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Booking failed: $e")));
      }
    }
  }
}
