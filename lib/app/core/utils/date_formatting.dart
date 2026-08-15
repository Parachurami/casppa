const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatShortDate(DateTime date) {
  return '${date.day} ${_monthAbbreviations[date.month - 1]}';
}

String formatLongDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

/// Whether [dueDate] has fully elapsed — true only once the calendar day
/// after [dueDate] has begun, so a due date of "today" is not yet overdue.
bool isPastDueDate(DateTime dueDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  return today.isAfter(dueDay);
}

String formatRelativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  return formatShortDate(date);
}
