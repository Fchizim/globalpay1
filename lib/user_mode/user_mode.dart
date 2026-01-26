import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.pin,
    this.phone = '',
    this.gender = '',
    this.address = '', required String password,
  });

  final String uid;
  final String name;
  final String email;
  final String pin;
  final String phone;
  final String gender;
  final String address;

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? pin,
    String? phone,
    String? gender,
    String? address,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      pin: pin ?? this.pin,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      address: address ?? this.address, password: '',
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      pin: json['pin'] ?? '',
      phone: json['phone'] ?? '',
      gender: json['gender'] ?? '',
      address: json['address'] ?? '', password: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'pin': pin,
      'phone': phone,
      'gender': gender,
      'address': address,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, pin: $pin, phone: $phone, gender: $gender, address: $address)';
  }

  @override
  List<Object?> get props => [uid, name, email, pin, phone, gender, address];
}
