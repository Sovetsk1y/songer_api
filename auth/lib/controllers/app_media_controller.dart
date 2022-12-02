import 'dart:io';
import 'dart:typed_data';

import 'package:auth/models/image.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit/conduit.dart';
import 'package:mime/mime.dart';

class AppMediaController extends ResourceController {
  final ManagedContext managedContext;

  AppMediaController(this.managedContext) {
    acceptedContentTypes.add(ContentType("multipart", "form-data"));
  }

  @Operation.get('name')
  Future<Response> getImage(@Bind.path('name') String fileName) async {
    final imageFile = File('public/images/$fileName');
    final imageByteStream = imageFile.openRead();
    final mimeType = lookupMimeType(imageFile.path);
    final response = Response.ok(imageByteStream)
      ..contentType = ContentType.parse(mimeType ?? 'application/octet-stream');
    return response;
  }

  @Operation.post()
  Future<Response> postForm() async {
    try {
      final boundary = request?.raw.headers.contentType?.parameters['boundary'];
      if (boundary?.isEmpty == true) {
        return AppResponse.badRequest(message: 'Wrong content type');
      }
      final transformer = MimeMultipartTransformer(boundary!);
      final bodyBytes = await request?.body.decode<List<int>>();

      final bodyStream = Stream.fromIterable([bodyBytes!]);
      final parts = await transformer.bind(bodyStream).toList();

      Uint8List? imageBytes;
      ContentType? contentType;

      for (var part in parts) {
        final headers = part.headers;
        contentType = ContentType.parse(headers['content-type'] ?? '');
        if (!contentType.mimeType.contains('image')) {
          continue;
        }
        final content = await part.single;
        final bytesBuilder = BytesBuilder();
        bytesBuilder.add(content);
        final bytes = bytesBuilder.toBytes();
        imageBytes = bytes;
        break;
      }
      if (imageBytes == null) {
        return AppResponse.badRequest(message: 'No image found');
      } else {
        var path = await _localPath;
        final fileName =
            '${AppUtils.getRandomString(16)}.${contentType!.subType}';
        path += '/public/images/$fileName';
        final file = File(path);
        file.writeAsBytes(imageBytes);
        final url = '${request?.path.string}/$fileName';
        final image = await _loadImageToDb(url);
        return AppResponse.ok(body: {
          'id': image.id,
          'url': url,
        }, message: 'Image successfully loaded');
      }
    } catch (e) {
      return Response.serverError(body: {
        'error': e.toString(),
      });
    }
  }

  Future<Image> _loadImageToDb(String url) async {
    final qCreateImage = Query<Image>(managedContext)..values.url = url;
    final image = await qCreateImage.insert();
    return image;
  }

  Future<String> get _localPath async {
    final directory = Directory.current;

    return directory.path;
  }
}
