import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  static const Color darkBlueText = Color(0xFF006064);
  static const Color primaryBlue = Color(0xFFE0F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Questions',
          style: TextStyle(color: darkBlueText, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: darkBlueText),
      ),
      body: _currentUser == null
          ? _buildNotSignedIn()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('doctor_questions')
                  .where('email', isEqualTo: _currentUser!.email)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: darkBlueText),
                  );
                }

                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  if (error.contains('PERMISSION_DENIED') ||
                      error.contains('Missing or insufficient permissions')) {
                    return _buildPermissionError();
                  } else if (error.contains('index') ||
                      error.contains('requires an index')) {
                    return _buildIndexError();
                  } else {
                    return _buildGenericError(error);
                  }
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoQuestions();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _QuestionCard(data: data, docId: doc.id);
                  },
                );
              },
            ),
    );
  }

  // ── Error widgets ─────────────────────────────────────────────────────────

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text('Permission Denied',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Firestore security rules need to allow read access to '
              'doctor_questions and doctor_user_data.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showSecurityRulesHelp,
              icon: const Icon(Icons.security),
              label: const Text('Show Fix'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 80, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text('Index Required',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'This query needs a Firestore composite index on '
              '"email" + "timestamp".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createIndexManually,
              icon: const Icon(Icons.build_circle),
              label: const Text('How to Create Index'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text('Error loading questions',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildNoQuestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No questions yet',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Submit your first question to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_circle),
            label: const Text('Ask a Question'),
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotSignedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Please sign in to view your questions',
              style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showSecurityRulesHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.security, color: Colors.red),
          SizedBox(width: 8),
          Flexible(child: Text('Fix Firestore Security Rules')),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Go to Firebase Console → Firestore → Rules and paste:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!)),
                child: const Text(
                  "rules_version = '2';\n"
                  "service cloud.firestore {\n"
                  "  match /databases/{db}/documents {\n"
                  "    match /doctor_questions/{d} {\n"
                  "      allow read, write:\n"
                  "        if request.auth != null;\n"
                  "    }\n"
                  "    match /doctor_user_data/{d} {\n"
                  "      allow read:\n"
                  "        if request.auth != null;\n"
                  "    }\n"
                  "  }\n"
                  "}",
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  void _createIndexManually() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.build_circle, color: Colors.orange),
          SizedBox(width: 8),
          Flexible(child: Text('Create Composite Index')),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Firebase Console → Firestore → Indexes → Create Index:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildStep(1, 'Collection ID: doctor_questions'),
              _buildStep(2, 'Field 1: email  →  Ascending'),
              _buildStep(3, 'Field 2: timestamp  →  Descending'),
              _buildStep(4, 'Query scope: Collection'),
              _buildStep(5, 'Click "Create" — wait 2–5 min'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8)),
                child: Text('After creating, press Retry in the app.',
                    style:
                        TextStyle(color: Colors.orange[800], fontSize: 12)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _buildStep(int n, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(11)),
            child: Center(
                child: Text('$n',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Safely converts a Firestore field that may be a [Timestamp] or an ISO [String]
/// into a [DateTime]. Returns null if the value is null or cannot be parsed.
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

// ── Question Card ─────────────────────────────────────────────────────────────
// StatefulWidget so it can asynchronously look up the answering doctor's
// name and specialty from the doctor_user_data collection.

class _QuestionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _QuestionCard({required this.data, required this.docId});

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  // Doctor info fetched from doctor_user_data
  String? _doctorName;
  String? _doctorSpecialty;
  bool _fetchingDoctor = false;

  @override
  void initState() {
    super.initState();
    // answeredBy holds the doctor's document ID in doctor_user_data
    final answeredBy = widget.data['answeredBy']?.toString();
    if (answeredBy != null && answeredBy.isNotEmpty) {
      _loadDoctorInfo(answeredBy);
    }
  }

  Future<void> _loadDoctorInfo(String doctorDocId) async {
    if (!mounted) return;
    setState(() => _fetchingDoctor = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('doctor_user_data')
          .doc(doctorDocId)
          .get();

      if (snap.exists && mounted) {
        final d = snap.data()!;
        setState(() {
          // doctor_user_data uses "username" for the doctor's display name
          _doctorName = d['username']?.toString();
          _doctorSpecialty = d['specialistArea']?.toString();
        });
      }
    } catch (e) {
      // Silently fail — the card will just show "Nephrologist"
      debugPrint('Could not fetch doctor info: $e');
    } finally {
      if (mounted) setState(() => _fetchingDoctor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    // Normalise status to lowercase so "Answered" == "answered"
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final isAnswered = status == 'answered';
    final statusColor = isAnswered ? Colors.green : Colors.orange;

    final DateTime? submittedDate = _parseDate(data['timestamp']);
    final DateTime? answeredDate = _parseDate(data['answeredAt']);
    final String answer = data['answer']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status badge + submitted date ──────────────────────
            Row(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          isAnswered ? Icons.check_circle : Icons.pending,
                          size: 13,
                          color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Submitted date
                if (submittedDate != null)
                  Text(
                    DateFormat('MMM dd, yyyy').format(submittedDate),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Category chip ──────────────────────────────────────
            if (data['category'] != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  data['category']!,
                  style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Question text ──────────────────────────────────────
            Text(
              data['question'] ?? 'No question text',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
            ),

            const SizedBox(height: 12),

            // ── Doctor response block ──────────────────────────────
            if (isAnswered && answer.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor identity row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.medical_services,
                              size: 22, color: Colors.green[700]),
                        ),
                        const SizedBox(width: 10),

                        // Name + specialty
                        Expanded(
                          child: _fetchingDoctor
                              ? Row(children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.green[600]),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Loading doctor info…',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[600])),
                                ])
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _doctorName ?? 'Nephrologist',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[800]),
                                    ),
                                    if (_doctorSpecialty != null)
                                      Text(
                                        _doctorSpecialty!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[600]),
                                      ),
                                  ],
                                ),
                        ),

                        // Answered date
                        if (answeredDate != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Answered',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[500])),
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(answeredDate),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                      ],
                    ),

                    Divider(
                        height: 20,
                        thickness: 1,
                        color: Colors.green[200]),

                    // Answer text
                    Text(
                      answer,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              )
            else if (!isAnswered)
              // Pending notice
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Awaiting review by a nephrologist — '
                        'usually within 48 hours.',
                        style: TextStyle(
                            color: Colors.orange[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
