import 'package:flutter/material.dart';
import '../models/kyc_model.dart';

class KycProvider extends ChangeNotifier {
  KycModel? _kyc;

  KycModel? get kyc => _kyc;

  // Accept nullable to allow resetting
  void setKyc(KycModel? model) {
    _kyc = model;
    notifyListeners();
  }
}