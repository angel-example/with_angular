import 'dart:async';
import 'dart:html';
import 'package:angel_note/models.dart';
import 'package:angel_note/validators.dart';
import 'package:angular2/angular2.dart';

@Component(selector: 'note-form', templateUrl: 'note_form.html')
class NoteFormComponent implements OnDestroy {
  final StreamController<Note> _noteChange = new StreamController<Note>.broadcast();
  final StreamController _submit = new StreamController();

  @Input()
  Note note = new Note();

  String title, text;

  // <note-form [(note)]="note"></note-form>

  @Output()
  Stream<Note> get noteChange => _noteChange.stream;

  @override
  ngOnDestroy() {
    _noteChange.close();
    _submit.close();
  }

  void handleSubmit() {
    Map data = {'title': note.title, 'text': note.text};

    if (CREATE_NOTE.check(data).errors.isNotEmpty)
      window.alert('Invalid note data.');
    else {
      _noteChange.add(note);
      _submit.add(null);
    }
  }
}