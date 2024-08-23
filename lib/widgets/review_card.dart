import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewCard extends StatelessWidget {
  final String teacherName;
  final String teacherInitials;
  final String courseCode;
  final double rating;
  final String review;
  final bool isAnonymous;
  final String authorName;
  final String? imageUrl;

  ReviewCard({
    required this.teacherName,
    required this.teacherInitials,
    required this.courseCode,
    required this.rating,
    required this.review,
    required this.isAnonymous,
    required this.authorName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$teacherName (${teacherInitials})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(courseCode, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 8),
            RatingBarIndicator(
              rating: rating,
              itemBuilder: (context, index) =>
                  Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20.0,
            ),
            SizedBox(height: 8),
            Text(review),
            SizedBox(height: 8),
            if (imageUrl != null) ...[
              SizedBox(height: 8),
              Image.network(imageUrl!),
            ],
            Text('Posted by: ${isAnonymous ? "Anonymous" : authorName}',
                style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),    
      ),
    );
  }
}
