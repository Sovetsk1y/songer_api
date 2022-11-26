import 'dart:io';

import 'package:auth/models/user.dart';
import 'package:auth/utils/app_const.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit/conduit.dart';

class AppUserController extends ResourceController {
  final ManagedContext managedContext;

  AppUserController(this.managedContext);

  @Operation.get()
  Future<Response> getProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(id);
      user?.removePropertiesFromBackingMap([
        AppConst.accessToken,
        AppConst.refreshToken,
      ]);
      return AppResponse.ok(
        message: 'Profile fetch succeeded',
        body: user?.backing.contents,
      );
    } catch (e) {
      return AppResponse.serverError(e, message: 'Get profile error');
    }
  }

  // @Operation.post()
  // Future<Response> updateProfile(
  //   @Bind.header(HttpHeaders.authorizationHeader) String header,
  //   @Bind.body() User user,
  // ) async {
  //   try {
  //     final id = AppUtils.getIdFromHeader(header);
  //     final fUser = await managedContext.fetchObjectWithID<User>(id);
  //     final qUpdateUser = Query<User>(managedContext)
  //       ..where((user) => user.id).equalTo(id)
  //       ..values.username = user.username ?? fUser?.username
  //       ..values.email = user.email ?? fUser?.email;
  //     await qUpdateUser.updateOne();
  //     final uUser = await managedContext.fetchObjectWithID<User>(id);
  //     uUser?.removePropertiesFromBackingMap([
  //       AppConst.accessToken,
  //       AppConst.refreshToken,
  //     ]);
  //     return AppResponse.ok(
  //       message: 'Profile update succeeded',
  //       body: uUser?.backing.contents,
  //     );
  //   } catch (e) {
  //     return AppResponse.serverError(e, message: 'Update profile error');
  //   }
  // }

  // @Operation.put()
  // Future<Response> updatePassword(
  //   @Bind.header(HttpHeaders.authorizationHeader) String header,
  //   @Bind.query('oldPassword') String oldPassword,
  //   @Bind.query('newPassword') String newPassword,
  // ) async {
  //   try {
  //     final id = AppUtils.getIdFromHeader(header);
  //     final qFindUser = Query<User>(managedContext)
  //       ..where((user) => user.id).equalTo(id)
  //       ..returningProperties((table) => [
  //             table.salt,
  //             table.hashPassword,
  //           ]);
  //     final findUser = await qFindUser.fetchOne();
  //     final salt = findUser?.salt ?? '';
  //     final oldPasswordHash = generatePasswordHash(
  //       oldPassword,
  //       salt,
  //     );
  //     if (oldPasswordHash != findUser?.hashPassword) {
  //       return AppResponse.badRequest(message: 'Password not valid');
  //     }
  //     final newPasswordHash = generatePasswordHash(newPassword, salt);
  //     final qUpdateUser = Query<User>(managedContext)
  //       ..where((user) => user.id).equalTo(id)
  //       ..values.hashPassword = newPasswordHash;
  //     await qUpdateUser.updateOne();
  //     return AppResponse.ok(message: 'Update password succeeded');
  //   } catch (e) {
  //     return AppResponse.serverError(e, message: 'Update password error');
  //   }
  // }
}
