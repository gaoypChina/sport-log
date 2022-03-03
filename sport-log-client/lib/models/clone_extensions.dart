import 'package:fixnum/fixnum.dart';

extension CloneDateTime on DateTime {
  DateTime clone() =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

extension CloneDuration on Duration {
  Duration clone() => Duration(seconds: inSeconds);
}

extension CloneInt64 on Int64 {
  Int64 clone() => Int64(toInt()); // TODO
}
