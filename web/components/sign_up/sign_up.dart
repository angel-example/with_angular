import 'dart:html';
import 'package:angel_note/validators.dart';
import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import '../../services/auth.dart';

@Component(selector: 'sign-up', templateUrl: 'sign_up.html')
class SignUpComponent {
  final AuthService _auth;
  String username, password;

  SignUpComponent(this._auth);

  void handleSubmit() {
    var data = {'username': username, 'password': password};

    if (CREATE_USER.check(data).errors.isNotEmpty)
      window.alert('Invalid data!');
    else _auth.signup(username, password);
  }
}