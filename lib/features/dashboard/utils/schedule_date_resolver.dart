DateTime resolveScheduleDate({
  required bool hasActiveTour,
  required String tourStartDate,
  required DateTime now,
  DateTime? requestedDate,
}) {
  if (hasActiveTour) {
    final parsedTourStartDate = DateTime.tryParse(tourStartDate.trim());
    if (parsedTourStartDate != null) {
      return parsedTourStartDate;
    }
  }

  return requestedDate ?? now;
}
