import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:angel_note/angel_note.dart';

main() async {
  // Look familiar? We can call this function to produce an identical server each time.
  // After all, we are the ones who wrote it. ;)
  var app = await createServer();

  // From `package:angel_diagnostics`, this plug-in colorfully prints information about
  // successful requests, as well as errors, to the console.
  //
  // You may optionally provide a log file to print to as well.
  await app.configure(logRequests());

  // Use `app.startServer` to bind to a socket and listen for HTTP requests.
  var server = await app.startServer(InternetAddress.ANY_IP_V4, 3000);

  // `app.startServer` returns an `HttpServer` instance, and we can print information about it.
  // We can also access the server by getting `app.httpServer`.
  print('Listening at http://${server.address.address}:${server.port}');
}