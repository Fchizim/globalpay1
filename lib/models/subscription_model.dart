// models/subscription_model.dart

class SubscriptionModel {
  final String subId;
  final String userId;
  final String planName;
  final double amount;
  final String status;
  final String startsAt;
  final String endsAt;
  final String paymentRef;
  final int autoRenew;
  final int daysLeft;

  SubscriptionModel({
    required this.subId,
    required this.userId,
    required this.planName,
    required this.amount,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.paymentRef,
    required this.autoRenew,
    required this.daysLeft,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      subId:      json['sub_id']      ?? '',
      userId:     json['user_id']     ?? '',
      planName:   json['plan_name']   ?? '',
      amount:     double.tryParse(json['amount'].toString()) ?? 0.0,
      status:     json['status']      ?? '',
      startsAt:   json['starts_at']   ?? '',
      endsAt:     json['ends_at']     ?? '',
      paymentRef: json['payment_ref'] ?? '',
      autoRenew:  json['auto_renew']  ?? 0,
      daysLeft:   json['days_left']   ?? 0,
    );
  }
}
