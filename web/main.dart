import 'package:angular2/platform/browser.dart';
import 'package:angular2/router.dart';
import 'components/note_app/note_app.dart';
import 'services/services.dart';

main() => bootstrap(NoteAppComponent, [ROUTER_PROVIDERS, NOTE_PROVIDERS]);
