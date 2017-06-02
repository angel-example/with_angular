/// Validators from `package:angel_validate` run on all platforms, and also
/// use the matchers you are already familiar with from testing via `package:matcher`.
import 'package:angel_validate/angel_validate.dart';

final Validator USER = new Validator({'username,password': isNonEmptyString});
final Validator CREATE_USER = USER.extend({})
  ..requiredFields.addAll(['username', 'password']);

final Validator NOTE = new Validator({'title,text': isNonEmptyString});
final Validator CREATE_NOTE = NOTE.extend({})
  ..requiredFields.addAll(['title', 'text']);
