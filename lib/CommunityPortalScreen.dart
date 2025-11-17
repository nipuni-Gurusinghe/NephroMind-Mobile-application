import 'package:flutter/material.dart';

class CommunityPortalScreen extends StatelessWidget {
  const CommunityPortalScreen({super.key});

  // Define the colors from the Dashboard
  static const Color darkBlueText = Color(0xFF006064);
  static const Color accentPurple = Color(0xFF9C27B0); 
  static const Color primaryBlue = Color(0xFFE0F7FA);

  // Sample data for the community threads
  final List<Map<String, String>> communityThreads = const [
    {
      'title': 'Tips for managing fluid intake on dialysis',
      'author': 'User_123',
      'replies': '25',
      'time': '3h ago'
    },
    {
      'title': 'Best low-sodium recipes for the week?',
      'author': 'ChefNephro',
      'replies': '15',
      'time': '1d ago'
    },
    {
      'title': 'Sharing my recent positive doctor visit!',
      'author': 'HappyKidney',
      'replies': '42',
      'time': '2d ago'
    },
    {
      'title': 'Looking for a specialist in Colombo',
      'author': 'Mr. Silva',
      'replies': '5',
      'time': '4d ago'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Portal',
          style: TextStyle(
            color: darkBlueText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: darkBlueText),
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8.0),
        itemCount: communityThreads.length,
        itemBuilder: (context, index) {
          final thread = communityThreads[index];
          return Card(
            elevation: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: accentPurple.withOpacity(0.1),
                child: Icon(Icons.forum, color: accentPurple),
              ),
              title: Text(
                thread['title']!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${thread['author']} • ${thread['replies']} replies • ${thread['time']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // TODO: Navigate to the individual Thread Detail Screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on: ${thread['title']}')),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to the New Post/Thread Creation Screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creating a new post...')),
          );
        },
        backgroundColor: accentPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}