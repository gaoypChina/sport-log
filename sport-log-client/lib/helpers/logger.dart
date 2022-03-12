import 'package:logger/logger.dart' as l;
import 'package:sport_log/config.dart';

export 'package:logger/logger.dart' show Level;

void logInfo(String key, String message) {
  final logger = Logger(key);
  logger.i(message);
}

class Logger extends l.Logger {
  Logger(String key)
      : super(
          printer: _Printer(key),
          level: Config.minLogLevel,
        );
}

class _Printer extends l.PrettyPrinter {
  _Printer(this.key)
      : super(methodCount: 0, errorMethodCount: 5, lineLength: 50);

  final String key;

  @override
  String stringifyMessage(dynamic message) {
    return '[$key] ' + super.stringifyMessage(message);
  }
}
