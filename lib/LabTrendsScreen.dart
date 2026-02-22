import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class LabTrendsScreen extends StatefulWidget {
  const LabTrendsScreen({super.key});

  @override
  State<LabTrendsScreen> createState() => _LabTrendsScreenState();
}

class _LabTrendsScreenState extends State<LabTrendsScreen> {
  static const Color primaryColor = Color(0xFF006064);
  static const Color primaryLight = Color(0xFFE0F7FA);

  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  String? _errorMessage;

  static const List<String> _labKeys = [
    'cr', 'al', 'ca', 'cl', 'k', 'ua', 'na', 'pr'
  ];

  static const Map<String, String> _labLabels = {
    'cr': 'Creatinine',
    'al': 'Albumin',
    'ca': 'Calcium',
    'cl': 'Chloride',
    'k':  'Potassium',
    'ua': 'Uric Acid',
    'na': 'Sodium',
    'pr': 'Total Protein',
  };

  static const Map<String, String> _labUnits = {
    'cr': 'mg/dL',
    'al': 'g/dL',
    'ca': 'mg/dL',
    'cl': 'mEq/L',
    'k':  'mEq/L',
    'ua': 'mg/dL',
    'na': 'mEq/L',
    'pr': 'g/dL',
  };

  static const Map<String, List<double>> _normalRanges = {
    'cr': [0.6, 1.2],
    'al': [3.5, 5.0],
    'ca': [8.5, 10.5],
    'cl': [98.0, 107.0],
    'k':  [3.5, 5.0],
    'ua': [2.4, 6.0],
    'na': [136.0, 145.0],
    'pr': [6.0, 8.3],
  };

  static const List<Color> _lineColors = [
    Color(0xFF006064),
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFF7043),
    Color(0xFF00ACC1),
    Color(0xFF6D4C41),
  ];

  late List<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = List.from(_labKeys);
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Not logged in.";
      });
      return;
    }
    try {
      final query = await FirebaseFirestore.instance
          .collection('ckd_results')
          .where('userId', isEqualTo: user.uid)
          .get();

      final docs = query.docs.map((d) => d.data()).toList();
      // Sort client-side — avoids needing a composite Firestore index
      docs.sort((a, b) {
        final ta = a['checkedAt'] as Timestamp?;
        final tb = b['checkedAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return ta.compareTo(tb);
      });

      setState(() {
        _records = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatDate(Map<String, dynamic> record) {
    final ts = record['checkedAt'];
    if (ts == null) return '?';
    final dt = (ts as Timestamp).toDate();
    return "${dt.day}/${dt.month}/${dt.year.toString().substring(2)}";
  }

  List<FlSpot> _getSpotsForKey(String key) {
    final spots = <FlSpot>[];
    for (int i = 0; i < _records.length; i++) {
      final val = _records[i]['lab_$key'];
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), (val as num).toDouble()));
      }
    }
    return spots;
  }

  /// Build unique x-axis labels. Same-day records get a suffix (#2, #3…)
  List<String> _buildXLabels() {
    final Map<String, int> dateCount = {};
    final List<String> labels = [];
    for (final record in _records) {
      final d = _formatDate(record);
      dateCount[d] = (dateCount[d] ?? 0) + 1;
      labels.add(dateCount[d]! > 1 ? '$d #${dateCount[d]}' : d);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lab Trends',
          style: TextStyle(
              color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? _buildError()
              : _records.isEmpty
                  ? _buildEmpty()
                  : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load data',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '',
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text('No lab records yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(
            'Upload your PDF from the dashboard\nto start tracking your lab trends.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            color: primaryLight,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.history, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${_records.length} check-up${_records.length > 1 ? 's' : ''} recorded',
                        style: const TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_records.length > 1)
                  Text(
                    '${_formatDate(_records.first)} → ${_formatDate(_records.last)}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Filter chips ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Lab Values to Display',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _labKeys.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final key = entry.value;
                    final isSelected = _selectedKeys.contains(key);
                    final color = _lineColors[idx % _lineColors.length];
                    return FilterChip(
                      label: Text(
                        _labLabels[key] ?? key,
                        style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.w600),
                      ),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedKeys.add(key);
                          } else {
                            _selectedKeys.remove(key);
                          }
                        });
                      },
                      selectedColor: color,
                      backgroundColor: color.withOpacity(0.1),
                      checkmarkColor: Colors.white,
                      side: BorderSide(color: color, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Main chart ─────────────────────────────────────────────────
          if (_selectedKeys.isNotEmpty)
            _buildMainChart()
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('Select at least one lab value above',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),

          const SizedBox(height: 20),

          // ── Individual cards ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text('Individual Lab Trends',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
          ),
          const SizedBox(height: 12),

          ..._labKeys.asMap().entries.map((entry) {
            final idx = entry.key;
            final key = entry.value;
            final spots = _getSpotsForKey(key);
            if (spots.isEmpty) return const SizedBox.shrink();
            return _buildIndividualCard(key, idx, spots);
          }),

          const SizedBox(height: 20),

          _buildRecordsTable(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // MAIN CHART
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildMainChart() {
    // ── Single record — no chart possible ─────────────────────────────
    if (_records.length < 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.08), blurRadius: 10)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lab Values Over Time',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Need at least 2 check-ups to show trends.\nUpload another PDF to see your progress.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 8),
              ..._selectedKeys.asMap().entries.map((e) {
                final key = e.value;
                final color =
                    _lineColors[e.key % _lineColors.length];
                final val = _records.first['lab_$key'];
                if (val == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(_labLabels[key] ?? key,
                          style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      Text('$val ${_labUnits[key] ?? ''}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    // ── Build line data ────────────────────────────────────────────────
    final lineBarsData = <LineChartBarData>[];
    for (int i = 0; i < _selectedKeys.length; i++) {
      final key = _selectedKeys[i];
      final spots = _getSpotsForKey(key);
      if (spots.isEmpty) continue;
      final color =
          _lineColors[_labKeys.indexOf(key) % _lineColors.length];
      lineBarsData.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, idx) =>
              FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white),
        ),
        belowBarData:
            BarAreaData(show: true, color: color.withOpacity(0.05)),
      ));
    }

    final xLabels = _buildXLabels();
    final int total = _records.length;

    // ── KEY FIX ───────────────────────────────────────────────────────
    // Set minX=0, maxX=total-1, and interval=1 so fl_chart places ticks
    // ONLY at integer positions 0, 1, 2 … (i.e. exactly at data points).
    // Without this, the chart auto-generates many fractional ticks between
    // 0 and 1, causing dozens of duplicate date labels.
    final double minX = 0;
    final double maxX = (total - 1).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.08), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lab Values Over Time',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
            const SizedBox(height: 4),
            Text('${_records.length} check-ups',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  // ✅ Constrain X range exactly to data points
                  minX: minX,
                  maxX: maxX,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    // ✅ Only draw vertical grid lines at integer positions
                    checkToShowVerticalLine: (v) =>
                        v == v.roundToDouble(),
                    getDrawingHorizontalLine: (v) => FlLine(
                        color: Colors.grey.shade100, strokeWidth: 1),
                    getDrawingVerticalLine: (v) => FlLine(
                        color: Colors.grey.shade100, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (val, meta) => Text(
                          val.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        // ✅ interval=1 means one tick per data point
                        interval: 1,
                        getTitlesWidget: (val, meta) {
                          final idx = val.round();
                          // Guard against out-of-range values
                          if (idx < 0 || idx >= total) {
                            return const SizedBox.shrink();
                          }
                          // Only show label at first and last point
                          // to keep the axis clean
                          if (idx != 0 && idx != total - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              xLabels[idx],
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.shade200)),
                  lineBarsData: lineBarsData,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF006064),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final barIndex = spot.barIndex;
                          final key = barIndex < _selectedKeys.length
                              ? _selectedKeys[barIndex]
                              : '';
                          final ptIdx = spot.x.toInt();
                          final dateLabel =
                              ptIdx >= 0 && ptIdx < xLabels.length
                                  ? xLabels[ptIdx]
                                  : '';
                          return LineTooltipItem(
                            '${_labLabels[key] ?? key}\n'
                            '${spot.y.toStringAsFixed(1)} ${_labUnits[key] ?? ''}\n'
                            '$dateLabel',
                            const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: _selectedKeys.map((key) {
                final color = _lineColors[
                    _labKeys.indexOf(key) % _lineColors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 14,
                        height: 3,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 5),
                    Text(_labLabels[key] ?? key,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // INDIVIDUAL CARD
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildIndividualCard(
      String key, int colorIdx, List<FlSpot> spots) {
    final color = _lineColors[colorIdx % _lineColors.length];
    final label = _labLabels[key] ?? key;
    final unit = _labUnits[key] ?? '';
    final range = _normalRanges[key];

    final double? latestVal = spots.isNotEmpty ? spots.last.y : null;
    final double? prevVal =
        spots.length > 1 ? spots[spots.length - 2].y : null;

    String status = 'Normal';
    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    if (range != null && latestVal != null) {
      if (latestVal > range[1]) {
        status = 'High';
        statusColor = Colors.red;
        statusIcon = Icons.arrow_upward;
      } else if (latestVal < range[0]) {
        status = 'Low';
        statusColor = Colors.orange;
        statusIcon = Icons.arrow_downward;
      }
    }

    double? change;
    if (latestVal != null && prevVal != null) change = latestVal - prevVal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text(key.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                        if (range != null)
                          Text('Normal: ${range[0]}–${range[1]} $unit',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (latestVal != null)
                        Text('${latestVal.toStringAsFixed(1)} $unit',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 3),
                          Text(status,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              if (change != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      change > 0
                          ? Icons.trending_up
                          : change < 0
                              ? Icons.trending_down
                              : Icons.trending_flat,
                      size: 14,
                      color: change > 0
                          ? Colors.red.shade400
                          : change < 0
                              ? Colors.green.shade600
                              : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change > 0
                          ? '+${change.toStringAsFixed(2)} from last check'
                          : '${change.toStringAsFixed(2)} from last check',
                      style: TextStyle(
                        fontSize: 11,
                        color: change > 0
                            ? Colors.red.shade400
                            : change < 0
                                ? Colors.green.shade600
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],

              if (spots.length > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (s, p, b, i) =>
                                FlDotCirclePainter(
                                    radius: 3,
                                    color: color,
                                    strokeWidth: 1,
                                    strokeColor: Colors.white),
                          ),
                          belowBarData: BarAreaData(
                              show: true,
                              color: color.withOpacity(0.08)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // RECORDS TABLE
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildRecordsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.08), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('All Check-up Records',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryColor)),
            ),
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFE0F7FA)),
                columnSpacing: 20,
                headingTextStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
                dataTextStyle: const TextStyle(
                    fontSize: 11, color: Colors.black87),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Diagnosis')),
                  DataColumn(label: Text('Cr')),
                  DataColumn(label: Text('Al')),
                  DataColumn(label: Text('Ca')),
                  DataColumn(label: Text('K')),
                  DataColumn(label: Text('Na')),
                  DataColumn(label: Text('Cl')),
                  DataColumn(label: Text('UA')),
                  DataColumn(label: Text('Pr')),
                ],
                rows: _records.reversed.map((record) {
                  final ts = record['checkedAt'];
                  final dt =
                      ts != null ? (ts as Timestamp).toDate() : null;
                  final dateStr = dt != null
                      ? "${dt.day}/${dt.month}/${dt.year}"
                      : '?';
                  final diagnosis =
                      record['diagnosisLabel']?.toString() ?? '?';
                  final hasCkd = record['hasCkd'] == true;

                  String cellVal(String key) {
                    final v = record['lab_$key'];
                    return v != null ? v.toString() : '-';
                  }

                  return DataRow(
                    color: WidgetStateProperty.all(hasCkd
                        ? Colors.red.shade50
                        : Colors.green.shade50),
                    cells: [
                      DataCell(Text(dateStr,
                          style: const TextStyle(fontSize: 10))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasCkd
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(diagnosis,
                            style: TextStyle(
                                fontSize: 9,
                                color: hasCkd
                                    ? Colors.red.shade800
                                    : Colors.green.shade800,
                                fontWeight: FontWeight.w600)),
                      )),
                      DataCell(Text(cellVal('cr'))),
                      DataCell(Text(cellVal('al'))),
                      DataCell(Text(cellVal('ca'))),
                      DataCell(Text(cellVal('k'))),
                      DataCell(Text(cellVal('na'))),
                      DataCell(Text(cellVal('cl'))),
                      DataCell(Text(cellVal('ua'))),
                      DataCell(Text(cellVal('pr'))),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
