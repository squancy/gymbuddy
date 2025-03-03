import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class PostBuilderViewModel {
  PostBuilderViewModel();

  String formatField(String field, Map<String, dynamic> post) {
    if (field == 'when') {
      return DateFormat('MM-dd hh:mm a').format(post[field].toDate()).toString();
    } else {
      return post[field];
    }
  }

  IconData getPostIcon(String field) {
    switch (field) {
      case 'gymName':
        return Icons.location_pin;
      case 'when':
        return Icons.calendar_month_rounded;
      case 'day_type':
        return Icons.sports_gymnastics_rounded;
    }
    return Icons.location_pin;
  }
}