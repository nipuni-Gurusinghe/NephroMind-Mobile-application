import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityPortalDataUploader extends StatefulWidget {
  const CommunityPortalDataUploader({super.key});

  @override
  State<CommunityPortalDataUploader> createState() => _CommunityPortalDataUploaderState();
}

class _CommunityPortalDataUploaderState extends State<CommunityPortalDataUploader> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;
  String _uploadStatus = '';

  // Updated multimedia data with REAL URLs
  final List<Map<String, dynamic>> _multimediaData = [
    // VIDEOS - Real YouTube URLs
    {
      'type': 'video',
      'title': 'Understanding Kidney Function',
      'description': 'Learn how kidneys work and their importance in filtering waste from your blood.',
      'url': 'https://www.youtube.com/watch?v=QpMdbW3eUYc', // Real YouTube URL
      'duration': '8:45',
      'category': 'Kidney Education',
      'views': 1250,
      'likes': 89,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },

    // INFOGRAPHICS - Real Image URLs
    {
      'type': 'infographic',
      'title': 'Kidney Health Warning Signs',
      'description': 'Visual guide to recognizing early warning signs of kidney problems.',
      'url': 'https://i.imgur.com/3QX5WQq.png', // Real image URL
      'category': 'Symptoms',
      'downloads': 320,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'type': 'infographic',
      'title': 'Healthy Foods for Kidneys',
      'description': 'Foods that support kidney health and function.',
      'url': 'https://i.imgur.com/9E2zM3q.png', // Real image URL
      'category': 'Nutrition',
      'downloads': 450,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },

    // AUDIO - Real Audio URLs
    {
      'type': 'audio',
      'title': 'Relaxation for Kidney Patients',
      'description': 'Guided relaxation techniques for stress management.',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Real audio URL
      'duration': '15:20',
      'category': 'Wellness',
      'plays': 150,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'type': 'audio',
      'title': 'Kidney Health Meditation',
      'description': 'Meditation session focused on kidney wellness.',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', // Real audio URL
      'duration': '10:30',
      'category': 'Mental Health',
      'plays': 210,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  // ... (rest of your uploader code remains the same)
  Future<void> _uploadData() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = 'Starting data upload...';
    });

    try {
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < _multimediaData.length; i++) {
        final data = _multimediaData[i];
        
        setState(() {
          _uploadStatus = 'Uploading ${i + 1}/${_multimediaData.length}: ${data['title']}';
        });

        try {
          await _firestore.collection('multimedia').add(data);
          successCount++;
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          errorCount++;
          debugPrint('Error uploading ${data['title']}: $e');
        }
      }

      setState(() {
        _uploadStatus = 'Upload completed!\nSuccess: $successCount\nErrors: $errorCount\nTotal: ${_multimediaData.length}';
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _uploadStatus = 'Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Portal Data Uploader'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadData,
              child: const Text('Upload Real Multimedia Data'),
            ),
            const SizedBox(height: 20),
            Text(_uploadStatus),
          ],
        ),
      ),
    );
  }
}