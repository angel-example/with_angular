import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angel_client/angel_client.dart';
import 'package:angel_note/models.dart';
import 'package:angel_note/validators.dart';
import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import 'backend.dart';
import 'error.dart';

@Injectable()
class AuthService {
  final BackendService _backend;
  final ErrorService _error;
  final Router _router;
  final StreamController<User> _onLogin =
      new StreamController<User>.broadcast();
  User _user;

  AuthService(this._backend, this._error, this._router) {
    _backend.app.authenticate().then(handleAuth).catchError((_) {
      // Fail silently..
    });
  }

  Stream<User> get onLogin => _onLogin.stream;

  User get user => _user;

  Future handleAuth(AngelAuthResult auth) async {
    _onLogin.add(_user = User.parse(auth.data));
  }

  Future login(String username, String password) {
    return _backend.app.authenticate(
        type: 'local',
        credentials: {'username': username, 'password': password}).then((auth) {
      return handleAuth(auth).then((_) {
        _router.navigate(['/NoteList']);
      });
    }).catchError(_error.handleError);
  }

  Future signup(String username, String password) {
    return _backend.app.post('/api/signup',
        body: {'username': username, 'password': password}).then((res) {
      var body = JSON.decode(res.body);

      if (USER.check(body).errors.isEmpty) {
        // Success...
        return login(username, password);
      } else {
        window.alert('Failed to signup!');
      }
    }).catchError(_error.handleError);
  }
}
