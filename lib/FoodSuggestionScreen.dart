import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

class FoodSuggestionScreen extends StatefulWidget {
  const FoodSuggestionScreen({super.key});

  @override
  State<FoodSuggestionScreen> createState() => _FoodSuggestionScreenState();
}

class _FoodSuggestionScreenState extends State<FoodSuggestionScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasResult = false;

  Map<String, dynamic>? _extractedLabs;
  List<dynamic> _recommendations = [];

  final String _apiUrl =
      "https://foodsuggestion-production.up.railway.app/recommend";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Category color mapping
  static const Map<String, Color> _categoryColors = {
    'Vegetable': Color(0xFF4CAF50),
    'Fruit': Color(0xFFFF9800),
    'Grain': Color(0xFF8D6E63),
    'Protein': Color(0xFFE57373),
    'Dairy': Color(0xFF42A5F5),
    'Beverage': Color(0xFF26C6DA),
    'Legume': Color(0xFF66BB6A),
    'Fish': Color(0xFF5C6BC0),
  };

  static const Map<String, IconData> _categoryIcons = {
    'Vegetable': Icons.eco,
    'Fruit': Icons.apple,
    'Grain': Icons.grain,
    'Protein': Icons.set_meal,
    'Dairy': Icons.water_drop,
    'Beverage': Icons.local_drink,
    'Legume': Icons.grass,
    'Fish': Icons.set_meal_outlined,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null) return;

      setState(() {
        _isLoading = true;
        _hasResult = false;
        _recommendations = [];
        _extractedLabs = null;
      });

      File file = File(result.files.single.path!);
      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint("📥 Status: ${response.statusCode}");
      debugPrint("📥 Body: ${response.body}");

      if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final detail = errorData['detail'];
        final String message = detail is Map
            ? detail['message'] ?? "Invalid medical PDF."
            : detail?.toString() ?? "No lab values found in PDF.";
        _showErrorDialog(message);
        return;
      }

      if (response.statusCode != 200) {
        _showSnackBar(
            "API Error ${response.statusCode}: ${response.reasonPhrase}");
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        _extractedLabs =
            data['extracted_labs'] as Map<String, dynamic>?;
        _recommendations = data['recommendations'] as List<dynamic>? ?? [];
        _hasResult = true;
      });

      _fadeController.reset();
      _fadeController.forward();
    } catch (e) {
      debugPrint("❌ Upload error: $e");
      _showSnackBar("Connection failed. Please check your internet.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              child: Text("Invalid PDF",
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message,
                style:
                    const TextStyle(fontSize: 14, color: Colors.black87)),
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
                  const Text("Upload a valid kidney function report:",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange)),
                  const SizedBox(height: 8),
                  _bullet("KFT (Kidney Function Test) report"),
                  _bullet("Renal panel with Creatinine / Sodium / Potassium"),
                  _bullet("Blood test with electrolyte values"),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAndUploadPdf();
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

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ",
              style: TextStyle(fontSize: 13, color: Colors.orange)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ── Lab values summary chip row ──────────────────────────────
  Widget _buildLabChips() {
    if (_extractedLabs == null || _extractedLabs!.isEmpty) {
      return const SizedBox.shrink();
    }

    final Map<String, String> labLabels = {
      'Creatinine': 'Cr',
      'Uric Acid': 'UA',
      'Calcium': 'Ca',
      'Sodium': 'Na',
      'Potassium': 'K',
      'Chloride': 'Cl',
      'Albumin': 'Alb',
      'Total Protein': 'TP',
    };

    final Map<String, double> thresholds = {
      'Creatinine': 1.5,
      'Uric Acid': 6.0,
      'Sodium': 145.0,
      'Potassium': 5.0,
      'Chloride': 107.0,
      'Albumin': 3.5,
      'Total Protein': 6.0,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _extractedLabs!.entries.map((entry) {
        final String key = entry.key;
        final dynamic val = entry.value;
        final String shortLabel = labLabels[key] ?? key;
        final bool isNull = val == null;
        final double? thr = thresholds[key];

        Color chipColor = Colors.teal.shade50;
        Color textColor = Colors.teal.shade800;
        IconData statusIcon = Icons.check_circle_outline;

        if (!isNull && thr != null) {
          final double numVal = (val as num).toDouble();
          if (key == 'Albumin' || key == 'Total Protein') {
            if (numVal < thr) {
              chipColor = Colors.orange.shade50;
              textColor = Colors.orange.shade800;
              statusIcon = Icons.arrow_downward;
            }
          } else {
            if (numVal > thr) {
              chipColor = Colors.red.shade50;
              textColor = Colors.red.shade700;
              statusIcon = Icons.arrow_upward;
            }
          }
        }

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isNull ? Colors.grey.shade100 : chipColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isNull
                    ? Colors.grey.shade300
                    : textColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNull ? Icons.remove_circle_outline : statusIcon,
                size: 12,
                color: isNull ? Colors.grey : textColor,
              ),
              const SizedBox(width: 4),
              Text(
                isNull
                    ? "$shortLabel: N/A"
                    : "$shortLabel: ${val.toStringAsFixed(1)}",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isNull ? Colors.grey : textColor),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  
  Widget _buildFoodCard(Map<String, dynamic> food, int index) {
    final String name = food['FoodName']?.toString() ?? 'Unknown';
    final String category = food['Category']?.toString() ?? '';
    final String suitable = food['SuitableForCKD']?.toString() ?? '';
    final String mlPrediction = food['ml_prediction']?.toString() ?? suitable;
    final double finalScore =
        (food['final_score'] ?? food['score'] ?? 0.0).toDouble();
    final double mlScore =
        (food['ml_score'] ?? 0.0).toDouble();

    final Color catColor =
        _categoryColors[category] ?? const Color(0xFF006064);
    final IconData catIcon =
        _categoryIcons[category] ?? Icons.restaurant;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) => Opacity(
        opacity: _fadeAnimation.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: index < 3
                      ? const Color(0xFF006064)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: index < 3
                            ? Colors.white
                            : Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(catIcon, color: catColor, size: 24),
              ),
              const SizedBox(width: 12),

              // Food details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ),
                        // ML badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: mlPrediction == 'Yes'
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: mlPrediction == 'Yes'
                                    ? Colors.green.shade200
                                    : Colors.red.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mlPrediction == 'Yes'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 10,
                                color: mlPrediction == 'Yes'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                mlPrediction == 'Yes' ? 'Safe' : 'Avoid',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: mlPrediction == 'Yes'
                                        ? Colors.green.shade700
                                        : Colors.red.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Category tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                            fontSize: 11,
                            color: catColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Score bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("ML Confidence",
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500)),
                                  Text(
                                      "${(mlScore * 100).toStringAsFixed(0)}%",
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF006064))),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: mlScore.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade100,
                                  color: const Color(0xFF006064),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty / upload prompt ─────────────────────────────────────
  Widget _buildUploadPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.upload_file_outlined,
                size: 50, color: Color(0xFF006064)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Upload Your Lab Report",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006064)),
          ),
          const SizedBox(height: 12),
          Text(
            "Get personalized kidney-safe food\nrecommendations based on your lab values",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          _buildUploadButton(),
          const SizedBox(height: 24),
          // Info cards
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _infoChip(Icons.science_outlined, "Lab Extraction"),
              const SizedBox(width: 8),
              _infoChip(Icons.psychology_outlined, "ML Powered"),
              const SizedBox(width: 8),
              _infoChip(Icons.restaurant_outlined, "Food Ranked"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF006064)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF006064),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _pickAndUploadPdf,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.upload_file, color: Colors.white),
      label: Text(
        _isLoading ? "Analyzing..." : "Upload PDF Report",
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006064),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        elevation: 0,
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
        title: const Text(
          'Food Suggestions',
          style: TextStyle(
              color: Color(0xFF006064),
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (_hasResult)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF006064)),
              onPressed: _pickAndUploadPdf,
              tooltip: "Upload new report",
            ),
        ],
      ),
      body: _hasResult ? _buildResultView() : _buildInitialView(),
    );
  }

  Widget _buildInitialView() {
    return _isLoading
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF006064)),
                SizedBox(height: 16),
                Text("Extracting lab values & analyzing...",
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          )
        : _buildUploadPrompt();
  }

  Widget _buildResultView() {
    return CustomScrollView(
      slivers: [
        // Header section
        SliverToBoxAdapter(
          child: Container(
            color: const Color(0xFFE0F7FA),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF006064), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "${_recommendations.length} Foods Recommended",
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006064)),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _pickAndUploadPdf,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006064),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("Re-upload",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text("Your Lab Values",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildLabChips(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Section title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    size: 18, color: Color(0xFF006064)),
                const SizedBox(width: 8),
                const Text(
                  "Kidney-Safe Foods for You",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006064)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006064),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text("ML Ranked",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Food list
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final food =
                    _recommendations[index] as Map<String, dynamic>;
                return _buildFoodCard(food, index);
              },
              childCount: _recommendations.length,
            ),
          ),
        ),
      ],
    );
  }
}