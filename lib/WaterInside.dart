import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart'; // Required for DateFormat

// --- 1. Firestore Service Class ---
class WaterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Collection for individual water intake logs
  static const String intakeCollectionName = 'waterIntake'; 
  // Collection for user metadata (including daily total and last reset date)
  static const String usersCollectionName = 'users'; 

  // Logs a new water intake entry to the 'waterIntake' collection.
  Future<void> logWaterIntake(String uid, int amount) async {
    if (uid.isEmpty) return;
    try {
      // Logs the single intake event
      await _firestore.collection(intakeCollectionName).add({
        'uid': uid,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Water intake logged successfully: $amount ml');
    } catch (e) {
      print('Error logging water intake: $e');
      rethrow;
    }
  }

  // Fetches the TOTAL water intake for the current day by SUMMING all logs.
  Future<int> fetchDailyIntake(String uid) async {
    if (uid.isEmpty) return 0;

    // Use LOCAL date for start of day, as Firestore queries for Timestamp are tricky with serverTimestamp().
    // We will use local comparison here, but rely on the saveLastIntake/loadAllWaterData logic for the 00:00 reset.
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day); 

    try {
      // Fetch logs from today onwards (based on local time)
      final snapshot = await _firestore
          .collection(intakeCollectionName)
          .where('uid', isEqualTo: uid)
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .get();

      int totalIntake = 0;
      for (var doc in snapshot.docs) {
        // Ensure 'amount' exists and is a number, default to 0
        totalIntake += (doc.data()['amount'] as num?)?.toInt() ?? 0;
      }
      return totalIntake;
    } catch (e) {
      print('Error fetching daily intake: $e');
      return 0;
    }
  }

  // *UPDATED FUNCTION:* Fetches aggregated intake for the last 7 days from the 'waterIntake' logs.
  Future<Map<DateTime, int>> fetchLast7DaysIntake(String uid) async {
    if (uid.isEmpty) return {};

    final now = DateTime.now();
    // Start of TODAY
    final startOfToday = DateTime(now.year, now.month, now.day);
    // Get the start of the day 6 days ago (to include today, making 7 days total)
    final sevenDaysAgo = startOfToday.subtract(const Duration(days: 6)); 

    try {
      final snapshot = await _firestore
          .collection(intakeCollectionName)
          .where('uid', isEqualTo: uid)
          // Filter logs from the start of 7 days ago up to now
          .where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo)
          .orderBy('timestamp', descending: false)
          .get();

      Map<DateTime, int> dailyIntake = {};
      
      // Initialize the map with 7 keys (DateTimes from 6 days ago to today) set to 0
      for (int i = 0; i < 7; i++) {
        final date = startOfToday.subtract(Duration(days: 6 - i));
        dailyIntake[date] = 0;
      }

      // Aggregate data by date
      for (var doc in snapshot.docs) {
        final timestamp = doc.data()['timestamp'] as Timestamp?;
        final amount = (doc.data()['amount'] as num?)?.toInt() ?? 0;

        if (timestamp != null) {
          // Normalize the timestamp to the start of its local day for grouping
          final intakeDateLocal = timestamp.toDate().toLocal();
          final dateKey = DateTime(intakeDateLocal.year, intakeDateLocal.month, intakeDateLocal.day);
          
          if (dailyIntake.containsKey(dateKey)) {
            dailyIntake[dateKey] = dailyIntake[dateKey]! + amount;
          }
          // Note: If a log falls outside the 7-day initialized window, it's ignored, which is correct.
        }
      }
      
      // Convert map to a list of entries and sort oldest to newest (by date key)
      final sortedEntries = dailyIntake.entries
          .toList()
          ..sort((a, b) => a.key.compareTo(b.key)); 

      // Convert back to a map
      return Map.fromEntries(sortedEntries);

    } catch (e) {
      print('Error fetching 7-day intake: $e');
      return {};
    }
  }


  // Saves the CURRENT total water intake and the date it was last updated to the 'users' collection.
  Future<void> saveLastIntake(String uid, int totalAmount) async {
    if (uid.isEmpty) return;
    final now = DateTime.now();
    // Save the local start of day (used for daily reset check)
    final todayDate = DateTime(now.year, now.month, now.day); 
    await _firestore.collection(usersCollectionName).doc(uid).set({
      'dailyWaterIntake': totalAmount, 
      'lastIntakeDate': todayDate, 
    }, SetOptions(merge: true)).catchError((e) {
      print('Error updating user daily intake: $e');
    });
  }

  // Fetches the user's metadata (including last check date) from 'users' collection.
  Future<Map<String, dynamic>> fetchUserWaterData(String uid) async {
    if (uid.isEmpty) return {};
    try {
      final doc = await _firestore.collection(usersCollectionName).doc(uid).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching user water data: $e');
      return {};
    }
  }
}

// Reusable Widget for Quick Add Buttons (No changes needed)
class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.amount,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  final int amount;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(color: WaterInsideScreen.accentWaterBlue, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: WaterInsideScreen.darkBlueText, size: 30),
                  Text(
                    '+$amount ml',
                    style: const TextStyle(
                      color: WaterInsideScreen.darkBlueText,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// --- Bar Chart Widget (Updated for 7-day data visualization) ---
class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.accentWaterBlue,
    required this.dailyIntakeData,
    required this.goalIntake,
  });

  final Color accentWaterBlue;
  final Map<DateTime, int> dailyIntakeData;
  final int goalIntake;

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Chart Data (Max 7 days)
    // Map entries are already sorted oldest to newest from the service function
    final List<MapEntry<DateTime, int>> sortedEntries = dailyIntakeData.entries.toList();

    // 2. Determine Max Y-axis Value
    final int maxIntake = sortedEntries.map((e) => e.value).fold(goalIntake, (a, b) => a > b ? a : b);
    // Ensure max value is a round number (nearest multiple of 500 or 1000) for aesthetics
    final double chartMaxValue = max(goalIntake.toDouble(), (maxIntake / 500).ceil() * 500.0);
    final double maxBarHeight = 150.0; // Fixed max height for the bar area

    if (chartMaxValue == 0 || sortedEntries.isEmpty) {
      return const Center(child: Text("No intake data for the last 7 days."));
    }

    // 3. Create Y-axis Labels
    // Create 5 labels (Max, 3/4, 1/2, 1/4, 0)
    final int step = (chartMaxValue ~/ 4); 
    final yAxisLabels = List.generate(5, (index) => step * (4 - index))
        .map((label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            '${label}', 
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        )).toList();
        
    // Reverse and remove the '0' label from the top for better alignment in the column
    final yAxisWidgets = yAxisLabels.reversed.toList().sublist(1).reversed.toList(); 

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y-axis
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...yAxisWidgets,
            const SizedBox(height: 10), // Space for X-axis labels
          ], 
        ),
        const SizedBox(width: 8),
        // Bar Chart Bars Area
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: sortedEntries.map((entry) {
                    int value = entry.value;
                    DateTime date = entry.key; // Local date already normalized to start of day

                    double normalizedHeight = value / chartMaxValue;
                    
                    // Highlight today's bar
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final isToday = date.day == today.day && date.month == today.month && date.year == today.year;

                    return Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Tooltip-like value display
                          Text(
                            '${value}',
                            style: TextStyle(
                              color: isToday ? WaterInsideScreen.darkBlueText : Colors.grey[600],
                              fontSize: 10,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
                          const SizedBox(height: 5),
                          // Bar Container
                          Container(
                            height: normalizedHeight * maxBarHeight, 
                            width: 25,
                            decoration: BoxDecoration(
                              color: isToday ? WaterInsideScreen.accentButtonBlue : accentWaterBlue.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 5),
              // X-axis Labels (Day of the week)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: sortedEntries.map((entry) {
                  DateTime date = entry.key; 
                  String dayLabel = DateFormat('E').format(date); // e.g., 'Mon'
                  
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final isToday = date.day == today.day && date.month == today.month && date.year == today.year;

                  return SizedBox(
                    width: 25,
                    child: Center(
                      child: Text(
                        dayLabel,
                        style: TextStyle(
                            color: isToday ? WaterInsideScreen.darkBlueText : Colors.grey[600], 
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal
                          ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// --- 2. Stateful Main Screen Widget ---
class WaterInsideScreen extends StatefulWidget {
  const WaterInsideScreen({super.key});

  // Define colors consistent with DashboardScreen
  static const Color primaryBlue = Color(0xFFE0F7FA);
  static const Color darkBlueText = Color(0xFF006064);
  static const Color lightBlueBackground = Color(0xFFB3E5FC);
  static const Color accentWaterBlue = Color(0xFF4FC3F7);
  static const Color accentButtonBlue = Color(0xFF29B6F6);
  static const Color cardBackgroundLight = Color(0xFFF8F8F8);

  @override
  State<WaterInsideScreen> createState() => _WaterInsideScreenState();
}

class _WaterInsideScreenState extends State<WaterInsideScreen> with WidgetsBindingObserver {
  final WaterService _waterService = WaterService();
  final TextEditingController _manualEntryController = TextEditingController();

  int _currentIntake = 0;
  bool _isLoading = true; 
  final int _goalIntake = 2000;
  // *NEW STATE VARIABLE:* To hold the 7 days of historical data
  Map<DateTime, int> _last7DaysData = {}; 

  User? _user;
  String _uid = '';
  Timer? _midnightResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
    
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _uid = _user!.uid;
      _loadAllWaterData(); // Combined data loading function
    } else {
        // Handle unauthenticated user case
        setState(() { _isLoading = false; });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload data on app resume to check for midnight reset
    if (state == AppLifecycleState.resumed) {
      if (_uid.isNotEmpty) {
        _loadAllWaterData();
      }
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualEntryController.dispose();
    _midnightResetTimer?.cancel(); 
    super.dispose();
  }


  // --- Combined Core Logic for Load and Chart Data Fetching ---
  Future<void> _loadAllWaterData() async {
    if (_uid.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    // 1. Handle Daily Reset (Check if last recorded intake date is before today)
    final userData = await _waterService.fetchUserWaterData(_uid);
    
    // lastIntakeDate might be a Timestamp or a DateTime
    final lastIntakeDateValue = userData['lastIntakeDate'];
    DateTime? lastIntakeDate;

    if (lastIntakeDateValue is Timestamp) {
      lastIntakeDate = lastIntakeDateValue.toDate();
    } else if (lastIntakeDateValue is DateTime) {
      lastIntakeDate = lastIntakeDateValue;
    }
      
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if it's the first time saving, or if the saved date is before today's date
    final isNewDay = lastIntakeDate == null || lastIntakeDate.isBefore(today);

    if (isNewDay) {
      // Reset the current intake in state and in the database
      _currentIntake = 0;
      await _waterService.saveLastIntake(_uid, 0); 
    } else {
      // If it's the same day, fetch the last saved total from the user's document
      _currentIntake = (userData['dailyWaterIntake'] as num?)?.toInt() ?? 0;
      // We still re-fetch total from logs for consistency, but the reset check is vital.
      // 2. Fetch Today's Total (to ensure tank reflects all logs since the last manual update)
      _currentIntake = await _waterService.fetchDailyIntake(_uid);
    }
    
    // 3. Fetch 7-Day Chart Data
    final last7DaysData = await _waterService.fetchLast7DaysIntake(_uid);

    
    setState(() {
      // If we reset, _currentIntake is 0. If not, it's the total from logs.
      // If we didn't reset, we re-fetch the total from logs to be safe.
      _currentIntake = isNewDay ? 0 : _currentIntake; 
      _last7DaysData = last7DaysData; // Update chart data state
      _isLoading = false; 
    });

    _setupMidnightResetCheck();
  }

  // Sets up a timer to trigger a data reload exactly at midnight (local time)
  void _setupMidnightResetCheck() {
    _midnightResetTimer?.cancel(); 

    final now = DateTime.now();
    // Calculate the start of the next day
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    print('Setting up reset timer for $nextMidnight (${timeUntilMidnight.inHours}h ${timeUntilMidnight.inMinutes.remainder(60)}m)');

    _midnightResetTimer = Timer(timeUntilMidnight, () {
      print('Midnight reset triggered.');
      _loadAllWaterData(); // Call the combined loading function to trigger the daily reset logic
    });
  }

  // Function to add and log water intake
  void _addWater(int amount) async {
    if (_uid.isEmpty || amount <= 0) return;

    final newIntake = _currentIntake + amount;
    
    // 1. Log the single entry to the 'waterIntake' collection for historical data
    await _waterService.logWaterIntake(_uid, amount);

    // 2. Update the user's total in the 'users' collection (for tank display/reset check)
    await _waterService.saveLastIntake(_uid, newIntake);
    
    // 3. Update the local state and re-fetch chart data for immediate update
    // We re-fetch the chart data to ensure absolute consistency with the newly added log.
    _loadAllWaterData();

    // Optionally update current intake optimistically for faster UI response:
    setState(() {
      _currentIntake = newIntake;
    });
  }

  // Function for manual water entry
  void _logManualEntry() {
    final text = _manualEntryController.text;
    final amount = int.tryParse(text);

    if (amount != null && amount > 0) {
      _addWater(amount);
      _manualEntryController.clear();
      FocusScope.of(context).unfocus(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$amount ml logged!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in.')),
      );
    }
    
    final size = MediaQuery.of(context).size;
    final double fillPercentage = _currentIntake / _goalIntake;
    final double waterHeightFactor = min(1.0, fillPercentage); 

    return Scaffold(
      backgroundColor: WaterInsideScreen.primaryBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WaterInsideScreen.darkBlueText),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Water Intake Tracker',
          style: TextStyle(
            color: WaterInsideScreen.darkBlueText,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  // --- Water Consumption Visualization Section ---
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(top: 20, bottom: 40),
                    color: WaterInsideScreen.primaryBlue,
                    child: Column(
                      children: [
                        const Icon(Icons.water_drop, color: WaterInsideScreen.darkBlueText, size: 50),
                        const SizedBox(height: 30),
                        const Icon(Icons.water_drop, color: WaterInsideScreen.accentWaterBlue, size: 80),
                        const SizedBox(height: 10),
                        // Water Glass / Goal Visualization
                        SizedBox(
                          width: size.width * 0.5,
                          child: AspectRatio(
                            aspectRatio: 0.8,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                // Base Glass Outline
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: WaterInsideScreen.darkBlueText.withOpacity(0.5), width: 3),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30), bottom: Radius.circular(5)),
                                    color: Colors.transparent,
                                  ),
                                ),
                                // Water Fill
                                FractionallySizedBox(
                                  heightFactor: waterHeightFactor,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: WaterInsideScreen.accentWaterBlue.withOpacity(0.8),
                                      borderRadius: BorderRadius.vertical(
                                          bottom: const Radius.circular(3),
                                          top: Radius.circular(waterHeightFactor < 1.0 ? 0 : 30)
                                        ),
                                      ),
                                    ),
                                  ),
                                // Current / Goal Text Overlay
                                Positioned.fill(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '$_currentIntake ml',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Current / $_goalIntake ml Goal',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Quick Add Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Add',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WaterInsideScreen.darkBlueText,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _QuickAddButton(
                                amount: 200, icon: Icons.local_cafe, backgroundColor: WaterInsideScreen.accentWaterBlue.withOpacity(0.1), onTap: () => _addWater(200)),
                            _QuickAddButton(
                                amount: 500, icon: Icons.local_cafe, backgroundColor: WaterInsideScreen.accentWaterBlue.withOpacity(0.1), onTap: () => _addWater(500)),
                            _QuickAddButton(
                                amount: 1000, icon: Icons.water_drop, backgroundColor: WaterInsideScreen.accentWaterBlue.withOpacity(0.1), onTap: () => _addWater(1000)),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // --- Manual Entry Section ---
                        const Text(
                          'Manual Entry',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WaterInsideScreen.darkBlueText,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _manualEntryController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Enter amount (ml)',
                                  prefixIcon: const Icon(Icons.sentiment_satisfied, color: Colors.grey),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: WaterInsideScreen.cardBackgroundLight,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _logManualEntry,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: WaterInsideScreen.accentButtonBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                              ),
                              child: const Text(
                                'Log',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // --- Daily Water Consumption Chart ---
                        const Text(
                          'Daily Water Consumption (Last 7 Days)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: WaterInsideScreen.darkBlueText,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: 1.5,
                            child: _BarChart(
                                accentWaterBlue: WaterInsideScreen.accentWaterBlue,
                                dailyIntakeData: _last7DaysData, // Pass the fetched data
                                goalIntake: _goalIntake,
                              ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: WaterInsideScreen.darkBlueText,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        currentIndex: 2, 
        onTap: (index) {
          // Handle navigation here
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