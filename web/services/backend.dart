import 'dart:html';
import 'package:angel_client/browser.dart';
import 'package:angular2/angular2.dart';

@Injectable()
class BackendService {
  final Map<String, Service> _services = {};

  // Queries an Angel server via its REST API. :)
  final Angel app = new Rest(window.location.origin);

  Service service(String path) =>
      _services.putIfAbsent(path, () => app.service(path));
}
