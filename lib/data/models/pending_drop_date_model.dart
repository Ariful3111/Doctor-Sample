class PendingDropDateModel {
  final bool success;
  final List<String> pendingDates;

  PendingDropDateModel({required this.success, required this.pendingDates});

  factory PendingDropDateModel.fromJson(Map<String, dynamic> json) {
    return PendingDropDateModel(
      success: json['success'] ?? false,
      pendingDates: List<String>.from(json['pendingdates'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'pendingdates': pendingDates};
  }
}
