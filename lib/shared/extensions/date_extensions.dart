extension DateApiFormat on DateTime {
  String toApiDate() {
    final yy = (year % 100).toString().padLeft(2, '0');
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '$yy-$mm-$dd';
  }
}
