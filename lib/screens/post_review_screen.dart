import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:rate_your_teacher/screens/home_screen.dart';

class PostReviewScreen extends StatefulWidget {
  @override
  _PostReviewScreenState createState() => _PostReviewScreenState();
}

class _PostReviewScreenState extends State<PostReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  final _teacherNameController = TextEditingController();
  final _teacherInitialsController = TextEditingController();
  final _courseCodeController = TextEditingController();
  double _rating = 3.0;
  String _review = '';
  bool _isAnonymous = false;
  File? _imageFile;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _teacherNameController.dispose();
    _teacherInitialsController.dispose();
    _courseCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    final int maxRetries = 3;
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('review_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask.whenComplete(() => {});
        final imageUrl = await snapshot.ref.getDownloadURL();
        return imageUrl;
      } catch (e) {
        attempts++;
        print('Error uploading image (Attempt $attempts): $e');

        if (attempts >= maxRetries) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to upload image after $maxRetries attempts. Error: $e'),
            ),
          );
          return null;
        }

        await Future.delayed(Duration(seconds: 2 * attempts));
      }
    }
    return null;
  }

  List<String> _generateSearchTokens(String input) {
    final List<String> tokens = [];
    final words = input.toLowerCase().split(' ');

    for (int i = 0; i < words.length; i++) {
      String token = '';
      for (int j = i; j < words.length; j++) {
        token += words[j];
        tokens.add(token);
      }
    }

    return tokens;
  }

  void _submitReview() async {
    if (_formKey.currentState!.validate()) {
      String _teacherName = _teacherNameController.text.trim();
      String _teacherInitials = _teacherInitialsController.text.trim();
      String _courseCode = _courseCodeController.text.trim();
      _formKey.currentState!.save();

      if (_teacherName.isEmpty ||
          _teacherInitials.isEmpty ||
          _courseCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      // Debug prints to check values after saving
      print('After save - Teacher Name: $_teacherName');
      print('After save - Teacher Initials: $_teacherInitials');
      print('After save - Course Code: $_courseCode');

      List<String> searchableTokens = [
        ..._generateSearchTokens(_teacherName),
        ..._generateSearchTokens(_teacherInitials),
        ..._generateSearchTokens(_courseCode),
      ];

      String? imageUrl;
      if (_imageFile != null) {
        setState(() {
          _isUploadingImage = true;
        });
        imageUrl = await _uploadImage(_imageFile!);
        setState(() {
          _isUploadingImage = false;
        });
      }

      try {
        // Firestore write operation
        await FirebaseFirestore.instance.collection('reviews').add({
          'teacherName': _teacherName,
          'teacherInitials': _teacherInitials,
          'courseCode': _courseCode,
          'rating': _rating,
          'review': _review,
          'isAnonymous': _isAnonymous,
          'authorName': _isAnonymous
              ? 'Anonymous'
              : FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
          'timestamp': FieldValue.serverTimestamp(),
          'imageUrl': imageUrl,
          'searchableFields': [
            _teacherName.toLowerCase(),
            _teacherInitials.toLowerCase(),
            _courseCode.toLowerCase(),
          ],
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review posted successfully')));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      } catch (e) {
        print('Error posting review: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error posting review: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Review')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            //Teacher Name
            TextFormField(
              controller: _teacherNameController,
              decoration: InputDecoration(
                labelText: 'Teacher Name',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                labelStyle: TextStyle(color: Colors.deepPurpleAccent.shade100),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter teacher name';
                }
                return null;
              },
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        right: 8.0), // Space between fields
                    child: TextFormField(
                      controller: _teacherInitialsController,
                      decoration: InputDecoration(
                        labelText: 'Teacher Initials',
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.deepPurpleAccent),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        labelStyle:
                            TextStyle(color: Colors.deepPurpleAccent.shade100),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter teacher initials';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 8.0), // Space between fields
                    child: TextFormField(
                      controller: _courseCodeController,
                      decoration: InputDecoration(
                        labelText: 'Course Code',
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.deepPurpleAccent),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        labelStyle:
                            TextStyle(color: Colors.deepPurpleAccent.shade100),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter course code';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rating widget

            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurpleAccent),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  RatingBar.builder(
                    initialRating: 3,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Review widget
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Review',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepPurpleAccent),
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                labelStyle: TextStyle(color: Colors.deepPurpleAccent.shade100),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your review';
                }
                return null;
              },
              onSaved: (value) => _review = value!.trim(),
            ),

            // Anonymous checkbox
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                // Background color to match the form
              ),
              child: CheckboxListTile(
                title: const Text(
                  'Post Anonymously',
                  style: TextStyle(color: Colors.deepPurpleAccent),
                ),
                value: _isAnonymous,
                onChanged: (bool? value) {
                  setState(() {
                    _isAnonymous = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity
                    .leading, // Optional: Adjust checkbox position
                activeColor: Colors
                    .deepPurpleAccent, // Color of the checkbox when checked
                checkColor: Colors.white, // Color of the checkmark
              ),
            ),

            const SizedBox(height: 16),

            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Upload Photo (optional)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.deepPurpleAccent, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16.0), // Rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0), // Padding
                      ),
                      child: const Text('Choose Photo'),
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                            16.0), // Rounded corners for the image
                        child: Image.file(
                          _imageFile!,
                          width: double.infinity, // Match width to container
                          fit: BoxFit
                              .cover, // Ensure image fits within container
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_isUploadingImage)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              Colors.deepPurpleAccent, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16.0), // Rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0), // Padding
                        ),
                        child: const Text('Submit Review'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
