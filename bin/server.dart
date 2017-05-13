import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:angel_note/angel_note.dart';

main() async {
  var app = await createServer();
  await app.configure(logRequests());
  var server = await app.startServer(InternetAddress.ANY_IP_V4, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}