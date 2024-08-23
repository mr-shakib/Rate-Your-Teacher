import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/review_card.dart';

class ReviewFeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Feed')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reviews available'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic>? data =
                  document.data() as Map<String, dynamic>?;

              if (data == null) {
                return const Center(child: Text('Error: No data available'));
              }

              return ReviewCard(
                teacherName: data['teacherName'] ?? 'Unknown Teacher',
                teacherInitials:
                    data['teacherInitials'] ?? '', // Null safety check
                courseCode: data['courseCode'] ?? 'Unknown Course',
                rating: (data['rating'] ?? 0.0) as double, // Type safety
                review: data['review'] ?? 'No review provided',
                isAnonymous: data['isAnonymous'] ?? false,
                authorName: data['isAnonymous'] ?? false
                    ? 'Anonymous'
                    : (data['authorName'] ?? 'Unknown Author'),
                imageUrl: data['imageUrl'] ?? '', // Null safety check
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
