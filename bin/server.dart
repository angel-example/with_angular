import 'dart:io';

import 'package:angel_hot/angel_hot.dart';
import 'package:angel_note/angel_note.dart';

main() async {

  // Hot reloading requires some configuration before starting.
  // We configure the relevant directories for this project. You can add as many as you like
  // There are far more options available when hot reloading than showed here
  var hot = new HotReloader(createServer, [
    new Directory('config'),
    new Directory('lib'),
    new Directory('web')
  ]);

  // Use `app.startServer` to bind to a socket and listen for HTTP requests.
  var server = await hot.startServer(InternetAddress.LOOPBACK_IP_V4, 3000);

  // `app.startServer` returns an `HttpServer` instance, and we can print information about it.
  // We can also access the server by getting `app.httpServer`.
  print('Hot Server Listening at http://${server.address.address}:${server.port}');
}
