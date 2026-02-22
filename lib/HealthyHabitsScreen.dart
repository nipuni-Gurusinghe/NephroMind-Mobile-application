import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HealthyHabitsScreen extends StatelessWidget {
  const HealthyHabitsScreen({super.key});

  static const Color primaryColor = Color(0xFF006064);
  static const Color primaryLight = Color(0xFFE0F7FA);

  // Category color mapping
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hydration': return Colors.blue;
      case 'diet': return Colors.orange;
      case 'exercise': return Colors.green;
      case 'sleep': return Colors.purple;
      case 'medication': return Colors.red;
      default: return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hydration': return Icons.water_drop;
      case 'diet': return Icons.restaurant;
      case 'exercise': return Icons.fitness_center;
      case 'sleep': return Icons.bedtime;
      case 'medication': return Icons.medication;
      default: return Icons.favorite;
    }
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
        title: const Text('Healthy Habits',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            decoration: const BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.favorite, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Kidney Health Habits',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                      Text('Build habits to protect your kidneys',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('healthyHabits')
                  .where('isActive', isEqualTo: true)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }

                // Fallback: if isActive index not ready, fetch all
                if (snapshot.hasError) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('healthyHabits').snapshots(),
                    builder: (context, snap2) {
                      if (!snap2.hasData || snap2.data!.docs.isEmpty) {
                        return _emptyState();
                      }
                      return _buildList(snap2.data!.docs);
                    },
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState();
                }
                return _buildList(snapshot.data!.docs);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No habits available yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final String title = data['title']?.toString() ?? 'Untitled';
        final String description = data['description']?.toString() ?? '';
        final String category = data['category']?.toString() ?? '';
        final List<dynamic> tips = data['tips'] as List<dynamic>? ?? [];
        final String imageUrl = data['imageUrl']?.toString() ?? '';

        final Color catColor = _getCategoryColor(category);
        final IconData catIcon = _getCategoryIcon(category);

        // Skip base64 images (too large), only use http URLs
        final bool hasValidImage = imageUrl.isNotEmpty && imageUrl.startsWith('http');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: catColor.withOpacity(0.15))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: catColor.withOpacity(0.15), shape: BoxShape.circle),
                      child: Icon(catIcon, color: catColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    if (category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(category,
                            style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasValidImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(imageUrl, height: 140, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      ),
                    if (hasValidImage) const SizedBox(height: 12),
                    if (description.isNotEmpty)
                      Text(description,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
                    if (tips.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Tips:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                      const SizedBox(height: 6),
                      ...tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 7, height: 7,
                              decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tip.toString(),
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
