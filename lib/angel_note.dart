import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:angel_framework/hooks.dart' as hooks;
import 'package:angel_security/hooks.dart' as auth;
import 'package:mongo_dart/mongo_dart.dart';
import 'models.dart';
import 'validators.dart';

Future<Angel> createServer() async {
  var app = new Angel();
  await app.configure(loadConfigurationFile());
  // app.lazyParseBodies = true;
  app.injectSerializer(JSON.encode);

  var db = new Db(app.mongo_db);
  await db.open();

  app.use('/api/users', new MongoService(db.collection('users')));
  app.use('/api/notes', new MongoService(db.collection('notes')));

  await app.configure(configureUsers);
  await app.configure(configureNotes);

  var auth = new AngelAuth(jwtKey: app.jwt_key, allowCookie: false);

  auth.strategies
      .add(new LocalAuthStrategy(localAuthVerifier(app.service('api/users'))));

  auth.serializer = (User user) async => user.id;
  auth.deserializer =
      (String id) => app.service('api/users').read(id).then(User.parse);

  await app.configure(auth);

  app.post('/auth/local', auth.authenticate('local'));

  app.chain(validate(CREATE_USER)).post('/api/signup',
          (RequestContext req, res) async {
        var body = await req.lazyBody();
        var user = await app.service('api/users').create(body);
        return user;
      });

  await app.configure(new PubServeLayer());

  var vDir = new VirtualDirectory();
  await app.configure(vDir);

  var indexFile = new File.fromUri(vDir.source.uri.resolve('index.html'));

  app.after.add((req, ResponseContext res) => res.sendFile(indexFile));
  app.responseFinalizers.add(gzip());

  return app;
}

LocalAuthVerifier localAuthVerifier(Service userService) {
  return (String username, String password) async {
    Iterable<Map> users = await userService.index({
      'query': {'username': username}
    });

    if (users.isEmpty)
      return false;
    else {
      var u = User.parse(users.first);
      if (u.password == password) return u;
    }
  };
}

configureUsers(Angel app) async {
  var service = app.service('api/users') as HookedService;

  service.before([
    HookedServiceEvent.INDEXED,
    HookedServiceEvent.CREATED,
    HookedServiceEvent.MODIFIED,
    HookedServiceEvent.UPDATED,
    HookedServiceEvent.REMOVED
  ], hooks.disable());

  service.beforeCreated.listen(hooks.chainListeners([
    validateEvent(CREATE_USER),
    hooks.addCreatedAt(),
    hooks.addUpdatedAt()
  ]));

  service.beforeRead.listen(auth.restrictToOwner(ownerField: 'id'));

  service.afterAll(hooks.remove('password'));
}

configureNotes(Angel app) async {
  var service = app.service('api/notes') as HookedService;

  service.before([
    HookedServiceEvent.READ,
    HookedServiceEvent.MODIFIED,
    HookedServiceEvent.UPDATED,
    HookedServiceEvent.REMOVED
  ], auth.restrictToOwner());

  service.beforeIndexed.listen(auth.queryWithCurrentUser());

  service.beforeCreated.listen(hooks.chainListeners([
    validateEvent(CREATE_NOTE),
    auth.associateCurrentUser(),
    hooks.addCreatedAt()
  ]));

  service.beforeModify(hooks.addUpdatedAt());
}
