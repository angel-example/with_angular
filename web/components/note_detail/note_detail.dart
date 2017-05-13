import 'dart:html';
import 'package:angel_note/models.dart';
import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import '../../services/auth.dart';
import '../../services/note.dart';
import '../note_form/note_form.dart';

@Component(
    selector: 'new-note',
    templateUrl: 'note_detail.html',
    directives: const [NoteFormComponent])
class NoteDetailComponent implements OnActivate, OnInit {
  final NoteService _service;
  final RouteParams _params;
  final AuthService _auth;

  bool loaded = false;
  Note note = new Note();

  NoteDetailComponent(this._service, this._params, this._auth);

  String get id => _params.get('id');

  void handleSubmit() {
    _service.updateNote(id, note.title, note.text).then((_) {
      window.alert('Successful update of note #$id!');
    }).catchError((_) {
      window.alert('Couldn\t update note #$id');
    });
  }

  loadNote() async {
    if (_auth.user != null) {
      _service.fetchNote(id).then((Note note) {
        this.note = note;
        loaded = true;
      }).catchError((_) {
        window.alert('Couldn\'t load note #$id');
      });
    }
  }

  @override
  routerOnActivate(ComponentInstruction nextInstruction,
      ComponentInstruction prevInstruction) {
    loadNote();
  }

  @override
  ngOnInit() {
    _auth.onLogin.listen((_) {
      if (loaded == false) loadNote();
    });
  }
}
