import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

class ProfileFieldRepository {
  ProfileFieldRepository();

  final CommonRepository _commonRepo = CommonRepository();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save new username or bio to db
  Future<void> saveNewData(
    String newData,
    int maxLen,
    String fieldName,
    {required bool isBio}) async {
    if (Characters(newData).length > maxLen) {
      return;
    }

    final userID = await _commonRepo.getUserID();
    final settingsDocRef = _db.collection('user_settings').doc(userID);

    await settingsDocRef.update({fieldName: newData});
  }
}