import 'auth.dart';
import 'backend.dart';
import 'error.dart';
import 'note.dart';

const List<Type> NOTE_PROVIDERS = const [
  ErrorService,
  BackendService,
  AuthService,
  NoteService
];
