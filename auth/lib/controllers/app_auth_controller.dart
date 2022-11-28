import 'package:auth/models/user.dart';
import 'package:auth/utils/app_env.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:auth/utils/app_validator.dart';
import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);

  @Operation.post()
  Future<Response> getConfirmationCode(@Bind.body() User user) async {
    if (user.phone == null) {
      return AppResponse.badRequest(message: 'Field [phone] is required');
    }
    if (!AppValidator.validatePhone(user.phone ?? '')) {
      return AppResponse.badRequest(message: 'Invalid phone number');
    }
    // TODO: – connect to sms service
    final confirmationCode = '1111';
    try {
      final qFindUser = Query<User>(managedContext)
        ..where((x) => x.phone).equalTo(user.phone)
        ..returningProperties((x) => [
              x.id,
              x.salt,
              x.lastSignInRequestTime,
            ]);
      final fetchedUser = await qFindUser.fetchOne();

      if (fetchedUser == null) {
        final salt = generateRandomSalt();
        final hashConfirmationCode = generatePasswordHash(
          confirmationCode,
          salt,
        );
        final qCreateUser = Query<User>(managedContext)
          ..values.phone = user.phone
          ..values.hashConfirmationCode = hashConfirmationCode
          ..values.salt = salt
          ..values.lastSignInRequestTime = DateTime.now();
        await qCreateUser.insert();
        return AppResponse.ok(
          body: {'isRegistered': false},
          message: 'Confirmation code has been successfully sent!',
        );
      } else {
        final difference =
            (fetchedUser.lastSignInRequestTime?.difference(DateTime.now()) ??
                    Duration.zero)
                .abs();
        if (difference.inSeconds < 120) {
          return AppResponse.badRequest(
              message:
                  'You must wait ${120 - difference.inSeconds} seconds to repeat that request');
        }
        final hashConfirmationCode = generatePasswordHash(
          confirmationCode,
          fetchedUser.salt ?? '',
        );
        final qUpdateUser = Query<User>(managedContext)
          ..where((x) => x.id).equalTo(fetchedUser.id)
          ..values.hashConfirmationCode = hashConfirmationCode
          ..values.lastSignInRequestTime = DateTime.now();
        final uUser = await qUpdateUser.updateOne();
        return AppResponse.ok(
          body: {
            'isRegistered': uUser?.name?.isNotEmpty == true,
          },
          message: 'Confirmation code has been successfully sent!',
        );
      }
    } catch (e) {
      return AppResponse.serverError(e, message: 'Get confirmation code error');
    }
  }

  @Operation.put()
  Future<Response> confirmIdentity(@Bind.body() User user) async {
    if (user.phone?.isEmpty == true || user.confirmationCode?.isEmpty == true) {
      return AppResponse.badRequest(
          message: 'Field [phone] and [confirmationCode] are required');
    }
    if (!AppValidator.validatePhone(user.phone ?? '')) {
      return AppResponse.badRequest(message: 'Invalid phone number');
    }
    final qFindUser = Query<User>(managedContext)
      ..where((x) => x.phone).equalTo(user.phone)
      ..returningProperties((x) => [
            x.id,
            x.phone,
            x.salt,
            x.hashConfirmationCode,
            x.name,
          ]);
    final fetchedUser = await qFindUser.fetchOne();
    if (fetchedUser == null) {
      return AppResponse.notFound(
          message: 'User with provided phone not found');
    }
    final salt = fetchedUser.salt;
    final hashConfirmationCode = generatePasswordHash(
      user.confirmationCode ?? '',
      salt ?? '',
    );
    if (fetchedUser.hashConfirmationCode != hashConfirmationCode) {
      return AppResponse.badRequest(message: 'Confirmation code denied');
    }
    if (fetchedUser.name?.isNotEmpty == true) {
      await _updateTokens(fetchedUser.id!, managedContext);
      final uUser =
          await managedContext.fetchObjectWithID<User>(fetchedUser.id ?? '');
      return AppResponse.ok(
        body: uUser?.backing.contents,
        message: 'Sign In succeeded',
      );
    } else {
      if (user.name?.isEmpty ?? true) {
        return AppResponse.badRequest(
            message: 'You have no account. Field [name] must be provided');
      }
      if (!AppValidator.validateUserName(user.name ?? '')) {
        return AppResponse.badRequest(
            message:
                '[name] must be greater than 2. Available characters: [a-z A-Z а-я А-Я]');
      }
      await managedContext.transaction((transaction) async {
        final qUpdateUser = Query<User>(transaction)
          ..where((x) => x.id).equalTo(fetchedUser.id)
          ..values.name = user.name;
        final uUser = await qUpdateUser.updateOne();
        await _updateTokens(uUser!.asMap()['id'], transaction);
      });
      final userData =
          await managedContext.fetchObjectWithID<User>(fetchedUser.id);
      return AppResponse.ok(
        body: userData?.backing.contents,
        message: 'Sign Up succeeded',
      );
    }
  }

  @Operation.post('refresh')
  Future<Response> refreshToken(
    @Bind.path('refresh') String refreshToken,
  ) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<User>(id);
      if (user?.refreshToken != refreshToken) {
        return AppResponse.unauthorized(message: 'Token is not valid');
      }
      await _updateTokens(id, managedContext);
      final uUser = await managedContext.fetchObjectWithID<User>(id);
      return AppResponse.ok(
        body: uUser?.backing.contents,
        message: 'Tokens refresh succeeded',
      );
    } catch (e) {
      return AppResponse.serverError(e, message: 'Refresh Token error');
    }
  }

  Future<void> _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, dynamic> tokens = _getTokens(id);
    final qUpdateTokens = Query<User>(transaction)
      ..where((user) => user.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];
    await qUpdateTokens.updateOne();
  }

  Map<String, dynamic> _getTokens(int id) {
    final key = AppEnv.secretKey;
    final accessClaimSet = JwtClaim(
      maxAge: Duration(minutes: AppEnv.time),
      otherClaims: {'id': id},
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, dynamic>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }
}
