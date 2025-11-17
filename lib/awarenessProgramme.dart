import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart'; // Import for sharing

class AwarenessProgramme extends StatelessWidget {
  const AwarenessProgramme({super.key});

  // Define the colors from the Dashboard
  static const Color darkBlueText = Color(0xFF006064);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color primaryBlue = Color(0xFFE0F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Awareness Programmes',
          style: TextStyle(
            color: darkBlueText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: darkBlueText),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('awareness_programmes')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: accentPurple,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading programmes',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentPurple,
                      ),
                      child: const Text('Go Back',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No programmes available',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please upload sample data first',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPurple,
                    ),
                    child: const Text('Go Back',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final programmes = snapshot.data!.docs;

          programmes.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final timeA = dataA['createdAt'] as Timestamp?;
            final timeB = dataB['createdAt'] as Timestamp?;
            if (timeA == null || timeB == null) return 0;
            return timeB.compareTo(timeA);
          });

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
            itemCount: programmes.length,
            itemBuilder: (context, index) {
              final doc = programmes[index];
              final docId = doc.id;
              final data = doc.data() as Map<String, dynamic>;

              final title = data['title'] ?? 'Untitled';
              final description = data['description'] ?? 'No description';
              final author = data['author'] ?? 'Unknown';
              final authorRole = data['authorRole'] ?? '';
              final category = data['category'] ?? 'General';
              final readTime = data['readTime'] ?? '';
              final views = data['views'] ?? 0;
              final likes = data['likes'] ?? 0;

              return Card(
                elevation: 1,
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _incrementViews(docId);
                    _showProgrammeDetails(context, docId, data);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: accentPurple,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (readTime.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    readTime,
                                    style:
                                        TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: darkBlueText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: accentPurple.withOpacity(0.1),
                              child: Text(
                                author.isNotEmpty
                                    ? author[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: accentPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    author,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (authorRole.isNotEmpty)
                                    Text(
                                      authorRole,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.remove_red_eye,
                                    size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  views.toString(),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.favorite,
                                    size: 16, color: Colors.red[300]),
                                const SizedBox(width: 4),
                                Text(
                                  likes.toString(),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _incrementViews(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('awareness_programmes')
          .doc(docId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error incrementing views: $e');
    }
  }

  Future<void> _toggleLike(String docId, bool isLiked) async {
    try {
      await FirebaseFirestore.instance
          .collection('awareness_programmes')
          .doc(docId)
          .update({
        'likes': FieldValue.increment(isLiked ? -1 : 1),
      });
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  Future<void> _toggleBookmark(String programmeId, bool isBookmarked) async {
    const String userId = 'CURRENT_AUTHENTICATED_USER_ID';
    if (userId == 'CURRENT_AUTHENTICATED_USER_ID') {
      debugPrint("Error: Placeholder USER_ID used. Bookmark function is disabled.");
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      if (isBookmarked) {
        await userRef.update({
          'bookmarkedProgrammes': FieldValue.arrayRemove([programmeId]),
        });
      } else {
        await userRef.set({
          'bookmarkedProgrammes': FieldValue.arrayUnion([programmeId]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    }
  }

  void _showProgrammeDetails(
      BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _ProgrammeDetailSheet(
          docId: docId,
          data: data,
          onLikeToggle: _toggleLike,
          onBookmarkToggle: _toggleBookmark,
        );
      },
    );
  }
}

// Detail Sheet Widget
class _ProgrammeDetailSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Function(String, bool) onLikeToggle;
  final Function(String, bool) onBookmarkToggle;

  const _ProgrammeDetailSheet({
    required this.docId,
    required this.data,
    required this.onLikeToggle,
    required this.onBookmarkToggle,
  });

  @override
  State<_ProgrammeDetailSheet> createState() => _ProgrammeDetailSheetState();
}

class _ProgrammeDetailSheetState extends State<_ProgrammeDetailSheet> {
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _isLoading = false;
  bool _isBookmarkLoading = false;

  static const String _currentUserId = 'CURRENT_AUTHENTICATED_USER_ID';

  @override
  void initState() {
    super.initState();
    _checkInitialBookmarkStatus();
  }

  Future<void> _checkInitialBookmarkStatus() async {
    if (_currentUserId == 'CURRENT_AUTHENTICATED_USER_ID') {
      debugPrint(
          "Warning: Placeholder USER_ID used. Cannot check bookmark status.");
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .get();

      if (userDoc.exists) {
        final bookmarkedList =
            (userDoc.data()?['bookmarkedProgrammes'] as List<dynamic>?)
                    ?.cast<String>() ??
                [];
        setState(() {
          _isBookmarked = bookmarkedList.contains(widget.docId);
        });
      }
    } catch (e) {
      debugPrint('Error checking bookmark status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBlueText = Color(0xFF006064);
    const Color accentPurple = Color(0xFF9C27B0);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('awareness_programmes')
              .doc(widget.docId)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!.data() as Map<String, dynamic>
                : widget.data;

            final views = data['views'] ?? 0;
            final likes = data['likes'] ?? 0;

            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data['category'] ?? 'General',
                            style: const TextStyle(
                              color: accentPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: darkBlueText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: accentPurple.withOpacity(0.1),
                          child: Text(
                            (data['author'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: accentPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['author'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                data['authorRole'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: _isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    await widget.onLikeToggle(
                                        widget.docId, _isLiked);
                                    setState(() {
                                      _isLiked = !_isLiked;
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_isLiked
                                            ? '❤️ Added to favorites!'
                                            : 'Removed from favorites'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                accentPurple),
                                      ),
                                    )
                                  : Icon(
                                      _isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _isLiked
                                          ? Colors.red
                                          : Colors.grey[600],
                                      size: 28,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Icons.remove_red_eye,
                            label: 'Views',
                            value: views.toString(),
                            color: Colors.blue,
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          _StatItem(
                            icon: Icons.favorite,
                            label: 'Likes',
                            value: likes.toString(),
                            color: Colors.red,
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          _StatItem(
                            icon: Icons.access_time,
                            label: 'Read Time',
                            value: data['readTime'] ?? 'N/A',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[300]),
                    const SizedBox(height: 20),
                    Text(
                      data['content'] ?? 'No content available',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final title = data['title'] ??
                                  'Check out this amazing programme!';
                              const url =
                                  'https://nephromind.app/programme/';

                              Share.share(
                                '$title\n\nRead more here: $url${widget.docId}',
                                subject: 'Awareness Programme: $title',
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentPurple,
                              side: BorderSide(color: accentPurple),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isBookmarkLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isBookmarkLoading = true;
                                    });
                                    await widget.onBookmarkToggle(
                                        widget.docId, _isBookmarked);

                                    setState(() {
                                      _isBookmarked = !_isBookmarked;
                                      _isBookmarkLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(_isBookmarked
                                            ? '🔖 Programme saved!'
                                            : 'Removed bookmark.'),
                                        duration: const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                            icon: _isBookmarkLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : Icon(_isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border),
                            label: Text(_isBookmarked ? 'Bookmarked' : 'Bookmark'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentPurple,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
