import 'package:angel_note/models.dart';
import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import '../../services/auth.dart';
import '../../services/note.dart';

@Component(
    selector: 'note-list',
    templateUrl: 'note_list.html',
    directives: const [ROUTER_DIRECTIVES])
class NoteListComponent implements OnActivate, OnInit {
  final AuthService auth;
  final NoteService _noteService;

  NoteListComponent(this.auth, this._noteService);

  List<Note> get notes => _noteService.notes;

  @override
  routerOnActivate(ComponentInstruction nextInstruction,
      ComponentInstruction prevInstruction) {
    if (auth.user != null)
      _noteService.fetchNotes();
  }

  @override
  ngOnInit() {
    auth.onLogin.listen((_) {
      _noteService.fetchNotes();
    });
  }
}
