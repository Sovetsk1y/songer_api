import 'package:auth/controllers/app_auth_controller.dart';
import 'package:auth/controllers/app_greetings_controller.dart';
import 'package:auth/controllers/app_media_controller.dart';
import 'package:auth/controllers/app_token_controller.dart';
import 'package:auth/controllers/app_user_controller.dart';
import 'package:auth/utils/app_env.dart';

import 'package:conduit/conduit.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final persistentStore = _initDb();
    managedContext = ManagedContext(
      ManagedDataModel.fromCurrentMirrorSystem(),
      persistentStore,
    );
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('greetings').link(() => AppGreetingsController())
    ..route('images/[:name]')
        .link(() => AppTokenController())!
        .link(() => AppMediaController())
    ..route('token/[:refresh]').link(() => AppAuthController(managedContext))
    ..route('user')
        .link(() => AppTokenController())!
        .link(() => AppUserController(managedContext));

  PostgreSQLPersistentStore _initDb() {
    print([
      AppEnv.dbHost,
      AppEnv.dbUsername,
      AppEnv.dbPassword,
      AppEnv.dbName,
    ]);
    return PostgreSQLPersistentStore(
      AppEnv.dbUsername,
      AppEnv.dbPassword,
      AppEnv.dbHost,
      int.tryParse(AppEnv.dbPort),
      AppEnv.dbName,
    );
  }
}
