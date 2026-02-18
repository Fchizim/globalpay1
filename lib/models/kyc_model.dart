class KycModel {
  final String tier;
  final String status;
  final String kycId;

  KycModel({
    required this.tier,
    required this.status,
    required this.kycId,
  });

  factory KycModel.fromJson(Map<String, dynamic> json) {
    return KycModel(
      tier: json['tier']?.toString() ?? "1",
      status: json['kyc_status'] ?? "none",
      kycId: json['kyc_id'] ?? "",
    );
  }
}