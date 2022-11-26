import 'package:auth/utils/app_response.dart';
import 'package:conduit/conduit.dart';

class AppGreetingsController extends ResourceController {
  @Operation.get()
  Future<Response> getGreetings() async {
    return AppResponse.ok(message: 'Приветствую тебя в Сонгере, путник!');
  }
}
