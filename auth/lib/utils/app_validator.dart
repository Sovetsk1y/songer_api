abstract class AppValidator {
  static bool validatePhone(String input) {
    final regExp = RegExp(r'^\+7[0-9]{10}$');
    return regExp.hasMatch(input);
  }

  static bool validateUserName(String input) {
    final regExp = RegExp(r'^[A-Z a-z а-я А-Я]{3,32}$');
    return regExp.hasMatch(input);
  }
}
