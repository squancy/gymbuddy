import 'package:get_time_ago/get_time_ago.dart';

class CustomMessages implements Messages {
  /// Prefix added before the time message.
  @override
  String prefixAgo() => '';

  /// Suffix added after the time message.
  @override
  String suffixAgo() => '';

  /// Message when the elapsed time is less than 15 seconds.
  @override
  String justNow(int seconds) => 'just now';

  /// Message for when the elapsed time is less than a minute.
  @override
  String secsAgo(int seconds) => '${seconds}s';

  /// Message for when the elapsed time is about a minute.
  @override
  String minAgo(int minutes) => '1m';

  /// Message for when the elapsed time is in minutes.
  @override
  String minsAgo(int minutes) => "${minutes}m";

  /// Message for when the elapsed time is about an hour.
  @override
  String hourAgo(int minutes) => '1h';

  /// Message for when the elapsed time is in hours.
  @override
  String hoursAgo(int hours) => '${hours}h';

  /// Message for when the elapsed time is about a day.
  @override
  String dayAgo(int hours) => '1d';

  /// Message for when the elapsed time is in days.
  @override
  String daysAgo(int days) => '${days}d';

  /// Word separator to be used when joining the parts of the message.
  @override
  String wordSeparator() => ' ';
}