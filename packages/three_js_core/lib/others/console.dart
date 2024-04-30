// ignore: camel_case_types
class Console {
  static void error(String message, [dynamic variables]) {
    _print(message, variables);
  }

  static void warn(String message, [dynamic variables]) {
    _print(message, variables);
  }

  static void info(String message, [dynamic variables]) {
    _print(message, variables);
  }

  static void _print(String message, [dynamic variables]) {
    print(message + (variables == null ? "" : variables.toString()));
  }
}
