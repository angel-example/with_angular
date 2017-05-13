import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import '../../services/auth.dart';

@Component(selector: 'app-menu', templateUrl: 'app_menu.html', directives: const [
  ROUTER_DIRECTIVES
])
class AppMenuComponent {
  final AuthService auth;

  AppMenuComponent(this.auth);
}