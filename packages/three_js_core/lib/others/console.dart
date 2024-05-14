import 'package:logger/logger.dart';

Console console = Console();

// ignore: camel_case_types
class Console {
  late Logger _logger;

  /// Returns true if this is a verbose logger
  static bool isVerbose = false;

  /// Gives access to internal logger
  Logger get rawLogger => _logger;

  /// Creates a instance of [FLILogger].
  /// In case [isVerbose] is `true`,
  /// it logs all the [verbose] logs to console
  Console() {
    _logger = Logger(
      printer: PrettyPrinter(
          methodCount: 2, // Number of method calls to be displayed
          errorMethodCount: 8, // Number of method calls if stacktrace is provided
          lineLength: 120, // Width of the output
          colors: true, // Colorful log messages
          printEmojis: true, // Print an emoji for each log message
          printTime: true // Should each log print contain a timestamp
      ),
      level: Level.all
    );
  }

    /// Logs error messages
  void error(Object? message) => _logger.e('Error Log', error: '⚠️ $message');

  /// Prints to console if [isVerbose] is true
  void verbose(Object? message){
    if(isVerbose){
      _logger.t(message.toString());
    }
  }
  /// Prints to console
  void warning(Object? message){
    _logger.w(message.toString());
  }
  /// Prints to console if [isVerbose] is true
  void info(Object? message){
    if(isVerbose){
      _logger.i(message.toString());
    }
  }
}
