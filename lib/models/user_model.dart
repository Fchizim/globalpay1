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
  final String accountNumber;
  final String accountName;
  final String dob;
  final String location;
  final String kycLevel;
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
    required this.accountNumber,
    required this.accountName,
    required this.dob,
    required this.location,
    required this.kycLevel,
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
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      dob: json['dob'] ?? '',
      location: json['location'] ?? '',
      kycLevel: json['kycLevel'] ?? '',
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
      'account_number': accountNumber,
      'account_name': accountName,
      'dob': dob,
      'location': location,
      'kycLevel': kycLevel,
      'is_verified': isVerified ? 1 : 0,
    };
  }

  /// ✅ copyWith method
  UserModel copyWith({
    int? id,
    String? userId,
    String? name,
    String? username,
    String? gender,
    String? email,
    String? phone,
    String? image,
    double? wallet,
    String? role,
    String? status,
    String? address,
    String? accountNumber,
    String? accountName,
    String? dob,
    String? location,
    String? kycLevel,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      image: image ?? this.image,
      wallet: wallet ?? this.wallet,
      role: role ?? this.role,
      status: status ?? this.status,
      address: address ?? this.address,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      dob: dob ?? this.dob,
      location: location ?? this.location,
      kycLevel: kycLevel ?? this.kycLevel,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}