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
  // Hospital names must match your Firestore "hospital" fields exactly
  final List<String> hospitals = [
    "Colombo National Hospital", 
    "Colombo East Base Hospital, Mullariyawa", 
    "Galle National Hospital",
    "Kandy General Hospital",
    "Jaffna Teaching Hospital",
  ];

  // The 3 fixed time slots per day as requested
  final List<String> timeSlots = [
    "09:00 AM - 10:00 AM",
    "10:00 AM - 11:00 AM",
    "11:00 AM - 12:00 PM"
  ];

  String? selectedHospital;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Book Appointment", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdown(),
            const SizedBox(height: 20),
            _buildDatePicker(),
            const SizedBox(height: 20),
            const Divider(),
            const Text("Available Doctors", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildDoctorList(),
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
      value: selectedHospital,
      items: hospitals.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
      onChanged: (val) => setState(() => selectedHospital = val),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      tileColor: Colors.teal.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: Text("Date: ${DateFormat('EEE, d MMM yyyy').format(selectedDate)}"),
      trailing: const Icon(Icons.calendar_month, color: Colors.teal),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2027), // Current year is 2026
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
    );
  }

  Widget _buildDoctorList() {
    if (selectedHospital == null) return const Center(child: Text("Please select a hospital above"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doctor_user_data')
          .where('hospital', isEqualTo: selectedHospital)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text("Error loading doctors: ${snapshot.error}");
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
        
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text("No doctors found for this hospital.");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(data['username'] ?? "Unknown Doctor", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['specialistArea'] ?? "General Specialist"),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () => _showSlotSelection(docs[index].id, data['username']),
                  child: const Text("Select Slot"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- SLOT SELECTION MODAL ---

  void _showSlotSelection(String doctorId, String doctorName) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('book_appointment')
              .where('doctor_id', isEqualTo: doctorId)
              .where('date', isEqualTo: formattedDate)
              .snapshots(),
          builder: (context, snapshot) {
            // If it buffers here, check VS Code console for the Index Creation link!
            if (snapshot.hasError) return const Center(child: Text("Error: Indexing needed. Check logs."));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            List<String> bookedSlots = snapshot.data!.docs.map((doc) => doc['timeSlot'] as String).toList();

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Available Slots for $doctorName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Date: $formattedDate", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  ...timeSlots.map((slot) {
                    bool isBooked = bookedSlots.contains(slot);
                    return ListTile(
                      title: Text(slot, style: TextStyle(color: isBooked ? Colors.red : Colors.black)),
                      trailing: isBooked 
                        ? const Text("Booked", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                        : ElevatedButton(
                            onPressed: () => _confirmBooking(doctorId, doctorName, slot, formattedDate),
                            child: const Text("Book"),
                          ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- SAVE TO FIREBASE ---

  void _confirmBooking(String docId, String docName, String slot, String date) async {
    // FIX: Define currentUser to solve the red line error
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Please log in again")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('book_appointment').add({
        'doctor_id': docId,
        'doctor_name': docName,
        'hospital_name': selectedHospital,
        'timeSlot': slot,
        'date': date,
        'isBooked': true,
        'patientId': currentUser.uid, // Corrected Auth ID
        'createdAt': FieldValue.serverTimestamp(), // Duplicate removed
      });

      if (mounted) {
        Navigator.pop(context); // Close BottomSheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appointment confirmed with $docName at $slot")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking failed: $e")));
      }
    }
  }
}