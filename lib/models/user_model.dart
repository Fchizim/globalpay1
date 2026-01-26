class UserModel {
  final int id;
  final String userId;
  final String name;
  final String username;
  final String gender;
  final String email;
  final String phone;
  final String image;
  final double wallet;
  final String role;
  final String status;
  final String address;
  final int kycStatus;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.gender,
    required this.email,
    required this.phone,
    required this.image,
    required this.wallet,
    required this.role,
    required this.status,
    required this.address,
    required this.kycStatus,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      image: json['image'] ?? '',
      wallet: double.tryParse(json['wallet'].toString()) ?? 0.0,
      role: json['role'] ?? '',
      status: json['status'] ?? '',
      address: json['address'] ?? '',
      kycStatus: int.tryParse(json['kyc_status'].toString()) ?? 0,
      isVerified: json['is_verified'].toString() == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'username': username,
      'gender': gender,
      'email': email,
      'phone': phone,
      'image': image,
      'wallet': wallet,
      'role': role,
      'status': status,
      'address': address,
      'kyc_status': kycStatus,
      'is_verified': isVerified ? 1 : 0,
    };
  }
}