import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import '../app_menu/app_menu.dart';
import '../log_in/log_in.dart';
import '../new_note/new_note.dart';
import '../note_detail/note_detail.dart';
import '../note_list/note_list.dart';
import '../sign_up/sign_up.dart';

@Component(
    selector: 'note-app',
    templateUrl: 'note_app.html',
    directives: const [ROUTER_DIRECTIVES, AppMenuComponent])
@RouteConfig(const [
  const Route(path: '/login', name: 'LogIn', component: LogInComponent),
  const Route(path: '/signup', name: 'SignUp', component: SignUpComponent),
  const Route(path: '/new', name: 'NewNote', component: NewNoteComponent),
  const Route(
      path: '/note/:id', name: 'NoteDetail', component: NoteDetailComponent),
  const Route(
      path: '/',
      name: 'NoteList',
      component: NoteListComponent,
      useAsDefault: true)
])
class NoteAppComponent {}
