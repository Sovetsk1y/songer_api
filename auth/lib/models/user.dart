import 'package:conduit/conduit.dart';

class User extends ManagedObject<_User> implements _User {}

class _User {
  @primaryKey
  int? id;

  @Column(nullable: true, indexed: true)
  String? name;

  @Column(unique: true, indexed: true)
  String? phone;

  @Serialize(input: true, output: false)
  String? confirmationCode;

  @Column(omitByDefault: true)
  String? hashConfirmationCode;

  @Column(nullable: true)
  String? accessToken;

  @Column(nullable: true)
  String? refreshToken;

  @Column(omitByDefault: true)
  String? salt;

  @Column(omitByDefault: true)
  DateTime? lastSignInRequestTime;
}
