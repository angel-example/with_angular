import 'dart:async';
import 'dart:html';
import 'package:angel_client/angel_client.dart';
import 'package:angel_note/models.dart';
import 'package:angular2/angular2.dart';
import 'package:angular2/router.dart';
import 'auth.dart';
import 'backend.dart';
import 'error.dart';

@Injectable()
class NoteService {
  final BackendService _backend;
  final ErrorService _error;
  final AuthService _auth;
  final Router _router;
  Service _service;
  bool _loaded = false;
  final List<Note> notes = [];

  NoteService(this._backend, this._error, this._router, this._auth) {
    _service = _backend.service('api/notes');
    _auth.onLogin.listen((_) {
      if (_loaded == false)
        fetchNotes();
    });
  }

  void fetchNotes() {
    _service.index().then((List<Map> notes) {
      this.notes
        ..clear()
        ..addAll(notes.map(Note.parse));
      _loaded = true;
    }).catchError(_error.handleError);
  }

  void createNote(Note note) {
    _service
        .create({'title': note.title, 'text': note.text}).then((Map result) {
      notes.insert(0, Note.parse(result));
      window.alert('Successfully created note!');
      _router.navigate([
        '/NoteDetail',
        {'id': result['id']}
      ]);
    }).catchError(_error.handleError);
  }

  Future<Note> fetchNote(String id) => _service.read(id).then(Note.parse);

  Future updateNote(String id, String title, String text) {
    return _service.modify(id, {'title': title, 'text': text});
  }
}
