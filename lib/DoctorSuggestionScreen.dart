import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorSuggestionScreen extends StatefulWidget {
  const DoctorSuggestionScreen({super.key});

  @override
  State<DoctorSuggestionScreen> createState() => _DoctorSuggestionScreenState();
}

class _DoctorSuggestionScreenState extends State<DoctorSuggestionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedArea;
  bool _isLoading = false;
  List<Map<String, dynamic>> _doctors = [];

  final List<String> _areas = [
    'Colombo','Gampaha','Kalutara','Kandy','Matale','Nuwara Eliya',
    'Galle','Matara','Hambantota','Jaffna','Kilinochchi','Mannar',
    'Mullaitivu','Vavuniya','Trincomalee','Batticaloa','Ampara',
    'Kurunegala','Puttalam','Anuradhapura','Polonnaruwa','Badulla',
    'Monaragala','Ratnapura','Kegalle',
  ];

  Future<void> _fetchDoctors(String area) async {
    setState(() { _isLoading = true; _doctors = []; });
    try {
      final query = await _firestore
          .collection('doctor_user_data')
          .where('area', isEqualTo: area)
          .get();
      setState(() {
        _doctors = query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      });
    } catch (e) {
      debugPrint("Error: $e");
      _showSnackBar("Failed to load doctors. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    // ✅ Exact Firestore field names from your collection
    final String name        = doctor['username']?.toString() ?? 'Unknown Doctor';
    final String specialty   = doctor['specialistArea']?.toString() ?? 'Nephrologist';
    final String hospital    = doctor['hospital']?.toString() ?? '';
    final String phone       = doctor['phone']?.toString() ?? '';
    final String area        = doctor['area']?.toString() ?? '';
    final String email       = doctor['email']?.toString() ?? '';
    final String avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : 'D';

    Color specialtyColor = const Color(0xFF006064);
    if (specialty.toLowerCase() == 'unspecified') specialtyColor = Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFE0F7FA), shape: BoxShape.circle),
                  child: Center(child: Text(avatarLetter,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF006064)))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: specialtyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: specialtyColor.withOpacity(0.3)),
                        ),
                        child: Text(specialty, style: TextStyle(fontSize: 11, color: specialtyColor, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.green.shade600),
                      const SizedBox(width: 3),
                      Text("Verified", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 12),
            if (hospital.isNotEmpty) _infoRow(Icons.local_hospital_outlined, hospital, Colors.blue.shade700),
            if (area.isNotEmpty)     _infoRow(Icons.location_on_outlined, area, Colors.red.shade400),
            if (email.isNotEmpty)    _infoRow(Icons.email_outlined, email, Colors.orange.shade700),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showSnackBar("📞 $phone"),
                      icon: const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF006064)),
                      label: Text(phone,
                          style: const TextStyle(color: Color(0xFF006064), fontWeight: FontWeight.w600, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF006064)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showSnackBar("✉️ $email"),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.shade400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      ),
                      child: Icon(Icons.email_outlined, size: 18, color: Colors.orange.shade600),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_selectedArea == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: const BoxDecoration(color: Color(0xFFE0F7FA), shape: BoxShape.circle),
              child: const Icon(Icons.person_search, size: 55, color: Color(0xFF006064)),
            ),
            const SizedBox(height: 24),
            const Text("Find Kidney Specialists",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF006064))),
            const SizedBox(height: 10),
            Text("Select your district from the\ndropdown above to see doctors near you",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _hintChip(Icons.verified, "Verified Doctors"),
                const SizedBox(width: 8),
                _hintChip(Icons.phone, "Direct Contact"),
              ],
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No doctors found in $_selectedArea",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text("Try selecting a different district",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _hintChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF006064)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF006064), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE0F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006064)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Doctor Suggestions',
            style: TextStyle(color: Color(0xFF006064), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFE0F7FA),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text("Select your district",
                      style: TextStyle(fontSize: 12, color: Color(0xFF006064), fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF006064), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedArea,
                            hint: const Text("e.g. Colombo, Kandy, Galle...",
                                style: TextStyle(fontSize: 14, color: Colors.grey)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF006064)),
                            style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                            items: _areas.map((area) => DropdownMenuItem(value: area, child: Text(area))).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedArea = value);
                                _fetchDoctors(value);
                              }
                            },
                          ),
                        ),
                      ),
                      if (_selectedArea != null)
                        GestureDetector(
                          onTap: () => setState(() { _selectedArea = null; _doctors = []; }),
                          child: const Icon(Icons.close, size: 18, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_selectedArea != null && !_isLoading && _doctors.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: Color(0xFF006064)),
                  const SizedBox(width: 6),
                  Text("${_doctors.length} doctor${_doctors.length > 1 ? 's' : ''} found in $_selectedArea",
                      style: const TextStyle(fontSize: 13, color: Color(0xFF006064), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF006064)),
                      SizedBox(height: 14),
                      Text("Finding doctors near you...", style: TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ))
                : _doctors.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) => _buildDoctorCard(_doctors[index]),
                      ),
          ),
        ],
      ),
    );
  }
}
