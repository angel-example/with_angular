import 'dart:html';
import 'package:angular2/angular2.dart';

@Injectable()
class ErrorService {
  void handleError(e, [st]) {
    window.alert(e.toString());
    window.console.error(e);
    if (st != null) window.console.error(st);
  }
}