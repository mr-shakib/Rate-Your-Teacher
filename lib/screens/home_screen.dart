import 'package:flutter/material.dart';
import 'review_feed_screen.dart';
import 'search_screen.dart';
import 'post_review_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _children = [
    ReviewFeedScreen(),
    SearchScreen(),
    PostReviewScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Search'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.rate_review), label: 'Review'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    if (index < 0 || index >= _children.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid tab selected')),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }
}
