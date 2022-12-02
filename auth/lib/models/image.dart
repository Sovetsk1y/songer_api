import 'package:conduit/conduit.dart';

class Image extends ManagedObject<_Image> implements _Image {}

class _Image {
  @primaryKey
  int? id;

  @Column(indexed: true)
  String? url;
}
