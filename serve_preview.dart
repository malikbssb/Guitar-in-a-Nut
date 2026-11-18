// Scratch static server used only for headless screenshots.
import 'dart:io';

const _types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript',
  '.wasm': 'application/wasm',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.css': 'text/css',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.bin': 'application/octet-stream',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.mjs': 'application/javascript',
};

Future<void> main(List<String> args) async {
  final root = args.isEmpty ? 'build/preview' : args[0];
  final port = args.length > 1 ? int.parse(args[1]) : 8099;

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('serving $root on http://127.0.0.1:$port');

  await for (final request in server) {
    final path = request.uri.path;
    final file = File(
      '$root${path == '/' ? '/index.html' : path}',
    ).absolute;

    if (await file.exists()) {
      final type =
          _types.entries
              .firstWhere(
                (entry) => file.path.endsWith(entry.key),
                orElse: () => MapEntry('', 'application/octet-stream'),
              )
              .value;
      request.response.headers.contentType = ContentType.parse(type);
      await file.openRead().pipe(request.response);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    }
  }
}
