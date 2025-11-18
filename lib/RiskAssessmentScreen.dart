import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  int _currentQuestion = 0;
  final Map<String, dynamic> _answers = {};
  
  static const Color darkBlueText = Color(0xFF006064);
  static const Color primaryBlue = Color(0xFFE0F7FA);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color accentOrange = Color(0xFFFFB74D);

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is your age group?',
      'key': 'age',
      'options': ['Under 30', '30-40', '41-50', '51-60', 'Over 60'],
      'scores': [0, 1, 2, 3, 4],
    },
    {
      'question': 'What is your occupation?',
      'key': 'occupation',
      'options': ['Farmer', 'Agricultural Worker', 'Office Worker', 'Other'],
      'scores': [3, 3, 1, 1],
    },
    {
      'question': 'What is your primary water source?',
      'key': 'waterSource',
      'options': ['Well Water', 'Pipe-borne Water', 'Bottled Water', 'River/Stream'],
      'scores': [3, 1, 0, 4],
    },
    {
      'question': 'Do you have a family history of kidney disease?',
      'key': 'familyHistory',
      'options': ['Yes', 'No', 'Not Sure'],
      'scores': [4, 0, 1],
    },
    {
      'question': 'Do you have diabetes?',
      'key': 'diabetes',
      'options': ['Yes', 'No', 'Pre-diabetic'],
      'scores': [4, 0, 2],
    },
    {
      'question': 'Do you have high blood pressure?',
      'key': 'bloodPressure',
      'options': ['Yes', 'No', 'Borderline'],
      'scores': [4, 0, 2],
    },
    {
      'question': 'How often do you use pesticides or chemicals?',
      'key': 'chemicalExposure',
      'options': ['Daily', 'Weekly', 'Rarely', 'Never'],
      'scores': [4, 3, 1, 0],
    },
    {
      'question': 'How much water do you drink daily?',
      'key': 'waterIntake',
      'options': ['Less than 1L', '1-2L', '2-3L', 'More than 3L'],
      'scores': [3, 1, 0, 0],
    },
  ];

  void _selectAnswer(int index) {
    setState(() {
      _answers[_questions[_currentQuestion]['key']] = {
        'answer': _questions[_currentQuestion]['options'][index],
        'score': _questions[_currentQuestion]['scores'][index],
      };
      
      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _showResults();
      }
    });
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      setState(() {
        _currentQuestion--;
      });
    }
  }

  void _showResults() {
    int totalScore = 0;
    _answers.forEach((key, value) {
      totalScore += value['score'] as int;
    });

    // Save assessment to Firebase
    FirebaseFirestore.instance.collection('risk_assessments').add({
      'answers': _answers,
      'totalScore': totalScore,
      'riskLevel': _getRiskLevel(totalScore),
      'timestamp': FieldValue.serverTimestamp(),
      'anonymous': true,
    });

    // Navigate to results screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RiskAssessmentResultScreen(
          score: totalScore,
          answers: _answers,
        ),
      ),
    );
  }

  String _getRiskLevel(int score) {
    if (score >= 20) return 'High';
    if (score >= 12) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Risk Assessment',
          style: TextStyle(
            color: darkBlueText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: darkBlueText),
      ),
      body: Column(
        children: [
          // Progress Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: primaryBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestion + 1} of ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: darkBlueText,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: accentPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white,
                  color: accentPurple,
                  minHeight: 6,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBlueText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Options
                  ...List.generate(
                    question['options'].length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OptionCard(
                        text: question['options'][index],
                        isSelected: _answers[question['key']]?['answer'] == question['options'][index],
                        onTap: () => _selectAnswer(index),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previousQuestion,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentPurple,
                        side: const BorderSide(color: accentPurple),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _answers.containsKey(question['key'])
                        ? (_currentQuestion < _questions.length - 1
                            ? () => setState(() => _currentQuestion++)
                            : _showResults)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: Text(
                      _currentQuestion < _questions.length - 1
                          ? 'Next'
                          : 'View Results',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Option Card Widget
class _OptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF9C27B0) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF9C27B0) : Colors.grey,
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF9C27B0) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? const Color(0xFF9C27B0) : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Results Screen
class RiskAssessmentResultScreen extends StatelessWidget {
  final int score;
  final Map<String, dynamic> answers;

  const RiskAssessmentResultScreen({
    super.key,
    required this.score,
    required this.answers,
  });

  static const Color darkBlueText = Color(0xFF006064);
  static const Color primaryBlue = Color(0xFFE0F7FA);
  static const Color accentPurple = Color(0xFF9C27B0);

  String get riskLevel {
    if (score >= 20) return 'High';
    if (score >= 12) return 'Medium';
    return 'Low';
  }

  Color get riskColor {
    if (score >= 20) return Colors.red;
    if (score >= 12) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assessment Results',
          style: TextStyle(
            color: darkBlueText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: darkBlueText),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [riskColor.withOpacity(0.7), riskColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Risk Level',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      riskLevel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: $score/32',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recommendations
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: accentPurple),
                        const SizedBox(width: 8),
                        const Text(
                          'Recommendations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._getRecommendations(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to doctor suggestions
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Finding doctors nearby...')),
                  );
                },
                icon: const Icon(Icons.local_hospital),
                label: const Text('Find a Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RiskAssessmentScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Assessment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentPurple,
                  side: BorderSide(color: accentPurple),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Community Portal'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getRecommendations() {
    if (score >= 20) {
      return [
        _RecommendationItem(
          icon: Icons.warning_amber,
          text: 'Consult a nephrologist as soon as possible',
        ),
        _RecommendationItem(
          icon: Icons.water_drop,
          text: 'Get your kidney function tested immediately',
        ),
        _RecommendationItem(
          icon: Icons.medication,
          text: 'Review all medications with your doctor',
        ),
        _RecommendationItem(
          icon: Icons.local_drink,
          text: 'Ensure you are drinking clean, filtered water',
        ),
      ];
    } else if (score >= 12) {
      return [
        _RecommendationItem(
          icon: Icons.calendar_today,
          text: 'Schedule a kidney function test within the next month',
        ),
        _RecommendationItem(
          icon: Icons.water_drop,
          text: 'Switch to filtered or bottled water if possible',
        ),
        _RecommendationItem(
          icon: Icons.fitness_center,
          text: 'Maintain a healthy diet and exercise regularly',
        ),
        _RecommendationItem(
          icon: Icons.monitor_heart,
          text: 'Monitor your blood pressure and blood sugar regularly',
        ),
      ];
    } else {
      return [
        _RecommendationItem(
          icon: Icons.check_circle,
          text: 'Your risk is low - keep up the good habits!',
        ),
        _RecommendationItem(
          icon: Icons.water_drop,
          text: 'Continue drinking adequate clean water daily',
        ),
        _RecommendationItem(
          icon: Icons.favorite,
          text: 'Maintain a balanced, kidney-friendly diet',
        ),
        _RecommendationItem(
          icon: Icons.calendar_today,
          text: 'Get routine health check-ups annually',
        ),
      ];
    }
  }
}

class _RecommendationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecommendationItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF9C27B0)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}