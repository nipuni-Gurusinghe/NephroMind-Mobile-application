import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';

import 'WaterInside.dart';
import 'ProfileScreen.dart';
import 'CommunityPortalScreen.dart';
import 'DialysisTrackerScreen.dart';
import 'AwarenessProgramme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasResult = false;
  bool _isSaved = false;

  String _riskLevel = "";
  String _diagnosis = "";
  Color _riskColor = Colors.grey;

  Map<String, dynamic>? _pendingApiResponse;
  String _pendingFileName = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String apiUrl =
      "https://ckdbackend-production-70a1.up.railway.app/predict";

  static const Map<String, Map<String, String>> _labFieldMeta = {
    'age':    {'label': 'Age',           'unit': 'years'},
    'gender': {'label': 'Gender',        'unit': ''},
    'cr':     {'label': 'Creatinine',    'unit': 'mg/dL'},
    'ua':     {'label': 'Uric Acid',     'unit': 'mg/dL'},
    'ca':     {'label': 'Calcium',       'unit': 'mg/dL'},
    'na':     {'label': 'Sodium',        'unit': 'mEq/L'},
    'k':      {'label': 'Potassium',     'unit': 'mEq/L'},
    'cl':     {'label': 'Chloride',      'unit': 'mEq/L'},
    'al':     {'label': 'Albumin',       'unit': 'g/dL'},
    'pr':     {'label': 'Total Protein', 'unit': 'g/dL'},
  };

  // ---------------------------------------------------------------
  // STEP 1: Upload PDF → validate → get result
  // ---------------------------------------------------------------
  Future<void> _pickAndUploadPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null) return;

      setState(() => _isLoading = true);

      final String pickedFileName = result.files.single.name;
      File file = File(result.files.single.path!);

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("📥 Status: ${response.statusCode}");
      debugPrint("📥 Body: ${response.body}");

      // ── 422: Not a valid medical PDF ───────────────────────────
      if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final detail = errorData['detail'];
        final String message = detail is Map
            ? detail['message'] ?? "Invalid medical PDF."
            : detail?.toString() ?? "Invalid medical PDF.";

        final List<dynamic> fieldsFound =
            detail is Map ? (detail['fields_found'] ?? []) : [];
        final int foundCount = fieldsFound.length;

        _showInvalidPdfDialog(message, foundCount);
        return;
      }

      // ── Other errors ────────────────────────────────────────────
      if (response.statusCode != 200) {
        _showSnackBar(
            "API Error ${response.statusCode}: ${response.reasonPhrase}");
        return;
      }

      // ── 200: Valid result ────────────────────────────────────────
      final Map<String, dynamic> data = jsonDecode(response.body);
      final prediction = data['prediction'];
      final String diagnosis =
          prediction['diagnosis_label']?.toString() ?? "Unknown";
      final String severityRaw =
          prediction['severity_label']?.toString() ?? "Unknown";
      final String severity =
          (severityRaw == "N/A" || severityRaw == "Unknown") ? "L" : severityRaw;

      Color riskColor;
      if (severity == "L") {
        riskColor = Colors.green;
      } else if (severity == "M") {
        riskColor = Colors.orange;
      } else if (severity == "H") {
        riskColor = Colors.red;
      } else {
        riskColor = Colors.grey;
      }

      setState(() {
        _diagnosis = diagnosis;
        _riskLevel = severity;
        _riskColor = riskColor;
        _hasResult = true;
        _isSaved = false;
        _pendingApiResponse = data;
        _pendingFileName = pickedFileName;
      });

      if (mounted) {
        _showSaveConfirmationSheet(
          diagnosis: diagnosis,
          severity: severity,
          riskColor: riskColor,
          prediction: prediction,
          extractedData:
              data['extracted_data'] as Map<String, dynamic>? ?? {},
          fileName: pickedFileName,
        );
      }
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      _showSnackBar("Connection failed. Check if FastAPI is running.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------
  // Invalid PDF dialog — shown when 422 is returned
  // ---------------------------------------------------------------
  void _showInvalidPdfDialog(String message, int fieldsFound) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.file_present_outlined,
                  color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Invalid PDF",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What to upload:",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  _bulletPoint("Kidney Function Test (KFT) report"),
                  _bulletPoint("Blood test with Creatinine / Sodium / Potassium"),
                  _bulletPoint("Renal panel lab report"),
                ],
              ),
            ),
            if (fieldsFound > 0) ...[
              const SizedBox(height: 12),
              Text(
                "Found $fieldsFound field(s) — need at least 3.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndUploadPdf(); // Let user try again immediately
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006064),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Try Again",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 13, color: Colors.orange)),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // STEP 2: Bottom sheet — results + lab values + Save / Discard
  // ---------------------------------------------------------------
  void _showSaveConfirmationSheet({
    required String diagnosis,
    required String severity,
    required Color riskColor,
    required Map<String, dynamic> prediction,
    required Map<String, dynamic> extractedData,
    required String fileName,
  }) {
    String severityLabel = severity;
    if (severity == "L") severityLabel = "Low";
    if (severity == "M") severityLabel = "Medium";
    if (severity == "H") severityLabel = "High";

    String riskLabel = severity;
    if (severity == "L") riskLabel = "LOW RISK";
    if (severity == "M") riskLabel = "MEDIUM RISK";
    if (severity == "H") riskLabel = "HIGH RISK";

    IconData riskIcon;
    if (severity == "L") {
      riskIcon = Icons.check_circle_rounded;
    } else if (severity == "M") {
      riskIcon = Icons.warning_rounded;
    } else {
      riskIcon = Icons.dangerous_rounded;
    }

    final int extractedCount =
        extractedData.values.where((v) => v != null).length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Analysis Complete",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006064),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Review your results before saving",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    children: [
                      // Risk Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: riskColor.withOpacity(0.3),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: riskColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(riskIcon,
                                  color: riskColor, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(riskLabel,
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: riskColor)),
                                  const SizedBox(height: 2),
                                  Text(diagnosis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Diagnosis Summary
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader(
                                Icons.summarize_outlined,
                                "Diagnosis Summary"),
                            const SizedBox(height: 12),
                            _buildDetailRow("Diagnosis", diagnosis),
                            const Divider(height: 16),
                            _buildDetailRow("Severity", severityLabel),
                            const Divider(height: 16),
                            _buildDetailRow("File", fileName),
                            const Divider(height: 16),
                            _buildDetailRow("Date & Time",
                                _formatDateTime(DateTime.now())),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Lab Values
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _sectionHeader(Icons.biotech_outlined,
                                    "Extracted Lab Values"),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: extractedCount > 0
                                        ? const Color(0xFF006064)
                                        : Colors.grey,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "$extractedCount/${extractedData.length} found",
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (extractedData.isEmpty)
                              Center(
                                child: Text(
                                  "No lab values extracted from PDF",
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade500),
                                ),
                              )
                            else
                              ...extractedData.entries
                                  .map((entry) => _buildLabValueRow(
                                        entry.key,
                                        entry.value,
                                        isLast: entry.key ==
                                            extractedData.keys.last,
                                      ))
                                  .toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info note
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: Color(0xFF006064)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Diagnosis results and lab values will be saved to your health records.",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Bottom buttons
                Padding(
                  padding: EdgeInsets.fromLTRB(24, 12, 24,
                      24 + MediaQuery.of(ctx).viewInsets.bottom),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showSnackBar("Result not saved.");
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Discard",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  setSheetState(() {});
                                  setState(() => _isSaving = true);

                                  final bool saved =
                                      await _saveCkdResultToFirestore(
                                    _pendingApiResponse!,
                                    _pendingFileName,
                                  );

                                  setState(() {
                                    _isSaving = false;
                                    _isSaved = saved;
                                  });

                                  if (mounted) Navigator.pop(ctx);
                                  if (saved) {
                                    _showSuccessSnackBar(
                                        "✓ Result saved to your health records!");
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006064),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.cloud_upload_outlined,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text("Save to Records",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // STEP 3: Save to Firestore
  // ---------------------------------------------------------------
  Future<bool> _saveCkdResultToFirestore(
      Map<String, dynamic> fullApiResponse, String fileName) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar("Error: No logged-in user found.");
      return false;
    }

    final String userId = currentUser.uid;

    if (!fullApiResponse.containsKey('prediction')) {
      _showSnackBar("Error: Unexpected API response format.");
      return false;
    }

    final prediction = fullApiResponse['prediction'] as Map<String, dynamic>;
    final Map<String, dynamic> extracted =
        fullApiResponse['extracted_data'] as Map<String, dynamic>? ?? {};

    String severityCode =
        prediction['severity_label']?.toString() ?? "Unknown";
    String severityFull = severityCode;
    if (severityCode == "L") severityFull = "Low";
    if (severityCode == "M") severityFull = "Medium";
    if (severityCode == "H") severityFull = "High";
    if (severityCode == "N/A" || severityCode == "Unknown") {
      severityFull = "Low";
      severityCode = "L";
    }

    final Map<String, dynamic> ckdRecord = {
      'userId': userId,
      'userEmail': currentUser.email ?? "Unknown",
      'hasCkd': prediction['has_ckd'] ?? false,
      'diagnosisLabel': prediction['diagnosis_label']?.toString() ?? "Unknown",
      'severityLabel': severityFull,
      'severityCode': severityCode,

      // Individual lab fields
      'lab_age':    extracted['age'],
      'lab_gender': extracted['gender'],
      'lab_cr':     extracted['cr'],
      'lab_ua':     extracted['ua'],
      'lab_ca':     extracted['ca'],
      'lab_na':     extracted['na'],
      'lab_k':      extracted['k'],
      'lab_cl':     extracted['cl'],
      'lab_al':     extracted['al'],
      'lab_pr':     extracted['pr'],

      'fileName': fileName,
      'checkedAt': FieldValue.serverTimestamp(),
      'checkedAtLocal': DateTime.now().toIso8601String(),
    };

    try {
      final docRef =
          await _firestore.collection('ckd_results').add(ckdRecord);
      debugPrint("✅ Saved → ckd_results/${docRef.id} | user: $userId");
      return true;
    } on FirebaseException catch (e) {
      debugPrint("❌ FirebaseException [${e.code}]: ${e.message}");
      String msg = "Could not save.";
      if (e.code == 'permission-denied') {
        msg = "Permission denied. Update Firestore Security Rules.";
      } else if (e.code == 'unavailable') {
        msg = "No internet connection.";
      }
      _showSnackBar(msg);
      return false;
    } catch (e) {
      debugPrint("❌ Unknown save error: $e");
      _showSnackBar("Unexpected error: $e");
      return false;
    }
  }

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------
  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF006064)),
        const SizedBox(width: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006064))),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ),
      ],
    );
  }

  Widget _buildLabValueRow(String key, dynamic value,
      {bool isLast = false}) {
    final meta = _labFieldMeta[key];
    final String label = meta?['label'] ?? key.toUpperCase();
    final String unit = meta?['unit'] ?? '';
    final bool isNull = value == null;

    String displayValue;
    if (isNull) {
      displayValue = "Not found";
    } else if (key == 'gender') {
      displayValue = value.toString() == 'M' ? 'Male' : 'Female';
    } else {
      displayValue =
          unit.isNotEmpty ? "$value $unit" : value.toString();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNull ? Colors.grey.shade300 : Colors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            Text(displayValue,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isNull ? Colors.grey.shade400 : Colors.black87)),
          ],
        ),
        if (!isLast) const Divider(height: 14),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.cloud_done, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: const Color(0xFF006064),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Risk display widget
  // ---------------------------------------------------------------
  Widget _buildRiskDisplay() {
    if (!_hasResult) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.analytics_outlined,
                  size: 30, color: Color(0xFF006064)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Risk Level',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('- -',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          const SizedBox(height: 4),
          const Text('Upload PDF\nto see result',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      );
    }

    String riskLabel = _riskLevel;
    if (_riskLevel == "L") riskLabel = "LOW";
    if (_riskLevel == "M") riskLabel = "MEDIUM";
    if (_riskLevel == "H") riskLabel = "HIGH";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _riskColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(Icons.analytics_outlined,
                size: 30, color: _riskColor),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Risk Level',
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        Text(riskLabel,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _riskColor)),
        Text(_diagnosis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 3),
        if (_isSaving)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: Colors.grey)),
              SizedBox(width: 4),
              Text('Saving...',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        else if (_isSaved)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_done, size: 12, color: Colors.green),
              SizedBox(width: 3),
              Text('Saved',
                  style: TextStyle(fontSize: 10, color: Colors.green)),
            ],
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off,
                  size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 3),
              Text('Not saved',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFFE0F7FA);
    const Color darkBlueText = Color(0xFF006064);
    const Color cardBackgroundLight = Color(0xFFF8F8F8);
    const Color accentPurple = Color(0xFF9C27B0);

    final User? currentUser = _auth.currentUser;
    final String displayName = currentUser?.displayName ?? "User";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: darkBlueText),
            onPressed: () {},
          ),
        ),
        title: const Text('NephroMind',
            style: TextStyle(
                color: darkBlueText,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 20.0),
              color: primaryBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : "U",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hello, $displayName',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlueText)),
                          const Text('Welcome back!',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Self-Check',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: darkBlueText)),
                              const SizedBox(height: 5),
                              const Text('Upload Medical PDF',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _pickAndUploadPdf,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF81C784),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10.0)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 25, vertical: 12),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : Text(
                                        _hasResult
                                            ? 'Re-Check'
                                            : 'Start Check-up',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: _buildRiskDisplay()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15.0,
                mainAxisSpacing: 15.0,
                childAspectRatio: 1.1,
                children: <Widget>[
                  _DashboardCard(
                    icon: Icons.calendar_month,
                    iconColor: Colors.purple,
                    title: 'Dialysis Tracker',
                    subtitle: 'Schedule\nAppointment',
                    buttonText: 'Schedule Appointment',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DialysisTrackerScreen())),
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  _DashboardCard(
                    icon: Icons.water_drop,
                    iconColor: Colors.lightBlue,
                    title: 'Water Intake',
                    subtitle: '1500 ml / 2000 ml',
                    progressValue: 0.75,
                    buttonText: 'Log Water',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WaterInsideScreen())),
                    showButton: true,
                    backgroundColor: cardBackgroundLight,
                  ),
                  _DashboardCard(
                    icon: Icons.restaurant,
                    iconColor: Colors.green,
                    title: 'Food Helper',
                    subtitle: 'Kidney-Safe Recipes',
                    buttonText: 'Browse',
                    onTap: () {},
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  _DashboardCard(
                    icon: Icons.person_search,
                    iconColor: Colors.orange,
                    title: 'Doctor Suggestions',
                    subtitle: 'Find Specialists',
                    buttonText: 'Explore',
                    onTap: () {},
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  _DashboardCard(
                    icon: Icons.people,
                    iconColor: accentPurple,
                    title: 'Community Portal',
                    subtitle: 'Health Tips & More',
                    buttonText: 'Read Tips',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPortalScreen())),
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                  _DashboardCard(
                    icon: Icons.campaign,
                    iconColor: Colors.redAccent,
                    title: 'Awareness Programs',
                    subtitle: 'Health Tips & More',
                    buttonText: 'View More',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AwarenessProgramme())),
                    backgroundColor: cardBackgroundLight,
                    showButton: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkBlueText,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        currentIndex: 0,
        onTap: (index) {
          if (index == 4) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Self-Check'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Food'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.progressValue,
    this.showButton = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final double? progressValue;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: iconColor, size: 35),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
              if (progressValue != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressValue!,
                  backgroundColor: Colors.grey[300],
                  color: iconColor,
                ),
              ],
              const SizedBox(height: 8),
              if (showButton && buttonText != null)
                Text(buttonText!,
                    style: TextStyle(
                        color: iconColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
