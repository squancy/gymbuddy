import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';

class HomePageViewModel extends ChangeNotifier {
  HomePageViewModel();

  ValueNotifier<int> selectedIndex = ValueNotifier(0);

  void onItemTapped(int index) {
    if (selectedIndex.value == index) return;
    selectedIndex.value = index; 
    notifyListeners();
  } 

  final List<TabItem> items = [
    TabItem(
      icon: Icons.home,
      title: 'Home',
    ),
    TabItem(
      icon: Icons.add_box_rounded,
      title: 'Post',
    ),
    TabItem(
      icon: Icons.people_alt_rounded,
      title: 'Buddies',
    ),
    TabItem(
      icon: Icons.account_box,
      title: 'Profile',
    ),
  ];
}