import 'dart:html';
import 'package:angel_note/validators.dart';
import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import '../../services/auth.dart';

@Component(selector: 'log-in', templateUrl: 'log_in.html')
class LogInComponent {
  final AuthService _auth;
  String username, password;

  LogInComponent(this._auth);

  void handleSubmit() {
    var data = {'username': username, 'password': password};

    if (CREATE_USER.check(data).errors.isNotEmpty)
      window.alert('Invalid data!');
    else _auth.login(username, password);
  }
}