import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_common/angel_common.dart';
import 'package:angel_framework/hooks.dart' as hooks; // Commonly-used hooks
import 'package:angel_security/hooks.dart' as auth; // Authorization hooks
import 'package:mongo_dart/mongo_dart.dart';
import 'models.dart';
import 'validators.dart';

/// A common pattern is to build the application server within a function.
/// This makes it easy to set up an identical server when running tests.
Future<Angel> createServer() async {
  // Initialize the server!
  var app = new Angel();

  // Automatically load a YAML configuration file from the `config/` directory.
  // This varies with the `ANGEL_ENV` environment variable and defaults to 'development'.
  // 'default' is also loaded, if present.
  //
  // Any loaded configuration will be added to `app.properties`.
  //
  // TIP: `app.jwt_key` and `app.properties['jwt_key'] will return the same value!
  await app.configure(loadConfigurationFile());

  // Why spend time parsing the body of every request, when we can just parse the body on-demand
  // when necessary?
  app.lazyParseBodies = true;

  // Replace the default serializer (uses `dart:mirrors`) with `JSON.encode`, which is faster.
  app.injectSerializer(JSON.encode);

  // Connect to MongoDB using the connection string stored in our configuration file.
  var db = new Db(app.mongo_db);
  await db.open();

  // Mount two services that control MongoDB collections.
  //
  // Read more about services on the wiki:
  // https://github.com/angel-dart/angel/wiki/Service-Basics
  app.use('/api/users', new MongoService(db.collection('users')));
  app.use('/api/notes', new MongoService(db.collection('notes')));

  // Below, we have written two plug-ins, each of which applies configuration
  // and authorization hooks to a corresponding service.
  await app.configure(configureUsers);
  await app.configure(configureNotes);

  // We use `package:angel_auth` to authenticate users within our application.
  // Note that `package:angel_auth` provides authentication, not authorization.
  var auth = new AngelAuth(jwtKey: app.jwt_key, allowCookie: false);

  // An `AngelAuth` instances controls strategies, which contain specific logic
  // to ascertain the identity of a user.
  //
  // A `LocalAuthStrategy` can be used to authenticate users when they attempt to
  // log in with a username and password.
  auth.strategies
      .add(new LocalAuthStrategy(localAuthVerifier(app.service('api/users'))));

  // `package:angel_auth` needs to know how to turn an authenticated user into
  // a unique identifier. This identifier is serialized in a JWT we send to the user
  // on successful authentication.
  auth.serializer = (User user) async => user.id;

  // Conversely, we also need to know how to determine a user's identity from a unique
  // identifier.
  //
  // Why not use our service to look up a user by ID?
  auth.deserializer =
      (String id) => app.service('api/users').read(id).then(User.parse);

  // `AngelAuth` instances act as plug-ins. When we call `app.configure`,
  // the plug-in injects some code that will automatically deserialize a user
  // from a JWT, if one was sent.
  //
  // The deserialized user will be injected into the request as 'user'.
  // Angel's DI system will inject the user into a function, so long as the function
  // has a parameter named 'user'.
  await app.configure(auth);

  // Set up a POST route that authenticates users via our `LocalAuthStrategy`.
  //
  // `auth.authenticate` returns a request handler that attempts to sign a user
  // in via the strategy with the given name. In this case, we use 'local'.
  app.post('/auth/local', auth.authenticate('local'));

  // This is a POST route that can be used to register a new user in the system.
  // We use `app.chain` to assign a middleware to run before our main handler.
  //
  // In this case, we used a validation middleware, which will automatically throw a
  // `400 Bad Request` error if the request body does not meet the `CREATE_USER` validation schema.
  app.chain(validate(CREATE_USER)).post('/api/signup',
          (RequestContext req, res) async {
        // As mentioned earlier, we can parse bodies on-demand.
        // The body will only actually be parsed once, no matter how many times
        // you call `req.lazyBody`.
        var body = await req.lazyBody();

        // A service's `create` method can be used to insert data into a collection.
        // In this case, we insert data into the 'users' collection in our MongoDB database.
        return await app.service('api/users').create(body);
      });

  // Another plug-in, this time from `package:angel_proxy`.
  // If `ANGEL_ENV` in our environment is not set to 'production', then
  // requests that have not been terminated by the earlier handlers will
  // be reverse proxied to a server at `127.0.0.1:8080` (usually `pub serve`
  // when working with Dart).
  //
  // This is extremely useful when developing full-stack Dart applications,
  // as we are in this example. :)
  await app.configure(new PubServeLayer());

  // The `VirtualDirectory` API from `package:angel_static` allows us to serve files
  // out of a directory in our filesystem.
  //
  // If you do not provide a `source` directory, the plug-in will guess one for you.
  // If `ANGEL_ENV` is set to 'production' in your environment, then it will default to
  // `build/web/`. If not, it chooses `web/` instead.
  //
  // With this configuration, our application will serve `pub serve` resources in development
  // mode, but in production, serve pre-built resources from `pub build`.
  var vDir = new VirtualDirectory();
  await app.configure(vDir);

  // This is how we support push-state routing in Angel.
  // Our `VirtualDirectory`'s source directory has already been determined,
  // so we can easily resolve the right `index.html` file.
  //
  // We serve that index file as a fallback, instead of a 404 page, and this
  // allows push-state routing in Angular2 to function correctly.
  var indexFile = new File.fromUri(vDir.source.uri.resolve('index.html'));
  app.after.add((req, ResponseContext res) => res.sendFile(indexFile));

  // Any request handler in `app.responseFinalizers` will *always* run
  // just before the response is actually sent to the client.
  //
  // The `gzip` function is provided by `package:angel_compress`, and compresses
  // outgoing response bodies via the GZIP algorithm.
  //
  // If you don't want to run any response finalizers (i.e. if you are writing directly to
  // the underlying `HttpResponse`), then set `willCloseItself` to `true` on a `ResponseContext`.
  app.responseFinalizers.add(gzip());

  // From `package:angel_diagnostics`, this plug-in colorfully prints information about
  // successful requests, as well as errors, to the console.
  //
  // You may optionally provide a log file to print to as well.
  await app.configure(logRequests());

  // And of course, return our `Angel` instance! Now, we can start up identical servers
  // simply by calling `createServer`.
  return app;
}

/// Returns a [LocalAuthVerifier] that attempts to sign a user in via username and password.
///
/// We use the [userService] to look users up.
LocalAuthVerifier localAuthVerifier(Service userService) {
  return (String username, String password) async {
    // Calling `index` returns a listing of all resources in
    // the collection. Typically this returns a `List` or another
    // `Iterable`, but it can technically return anything.
    //
    // We use a 'query' to limit the search to only users with
    // matching usernames.
    //
    // Since we are using a `MongoService`, the contents will be `Maps`.
    // However, were we using a `TypedService`, the contents would not be
    // `Maps`, but instances of a model class. So be careful with your
    // type annotations if running in checked mode.
    Iterable<Map> users = await userService.index({
      'query': {'username': username}
    });

    // The result of our verifier function expresses if the user was successfully
    // signed in.
    //
    // We can return `false` to signify that there was an authentication failure,
    // like an invalid username or password.
    if (users.isEmpty)
      return false;
    else {
      // In this tutorial, we did not hash passwords, and actually stored them
      // in plaintext. As you can imagine, this is insecure, and shouldn't be
      // done in practice. In the real world, you'd need to hash `password` to
      // compare it to the records in the database.
      //
      // If the first user we find has the right password, we return that user.
      // This user is then serialized by `auth.serializer`, and used to create a
      // JWT. Cool, huh?
      var u = User.parse(users.first);
      if (u.password == password) return u;
    }

    // Returning `null` has the same effect as returning `false`.
    // We needn't add any fallback code here, because by this point,
    // it will automatically return `null`.
  };
}

/// Applies configuration to the `api/users` service.
configureUsers(Angel app) async {
  // Angel services by default are wrapped in a `HookedService`
  // when you call `app.use`. Let's get a reference to that here.
  var service = app.service('api/users') as HookedService;

  // See the wiki for an explanation of service hooks:
  // https://github.com/angel-dart/angel/wiki/Hooks
  //
  // If you didn't read it, just know that hooks are functions
  // that can run before or after service methods, and can either
  // overwrite the method's result, or change the input data provided.

  // `hooks.disable` throws a `405 Method Not Allowed` error when a *client*
  // attempts to call the corresponding service method. The server is still free
  // to do whatever it wants.
  //
  // The below setup prevents random people on the Internet from writing to our
  // 'users' MongoDB collection. Clients can *only* get a user by ID, nothing else.
  service.before([
    HookedServiceEvent.INDEXED,
    HookedServiceEvent.CREATED,
    HookedServiceEvent.MODIFIED,
    HookedServiceEvent.UPDATED,
    HookedServiceEvent.REMOVED
  ], hooks.disable());

  // Use `hooks.chainListeners` to save keystrokes, and run multiple hooks in sequence.
  service.beforeCreated.listen(hooks.chainListeners([
    // Validates input data against the `CREATE_USER` validation schema.
    // If the input data is invalid, a `400 Bad Request` error is thrown, and no data
    // will be inserted into the database.
    validateEvent(CREATE_USER),
    // Serializes the current time into an ISO8601 string, and then adds it to the input data
    // as 'createdAt'.
    //
    // Technically, you can change the name from 'createdAt' to something else, or just pass the current
    // time as a `DateTime` instead of serializing, but in most cases, the default configuration works
    // just fine.
    hooks.addCreatedAt(),
    // Same as `hooks.addCreatedAt`, but instead uses the name `updatedAt`.
    hooks.addUpdatedAt()
  ]));

  // When called with the default arguments, `auth.restrictToOwner` will
  // throw a `403 Fobidden` error if the requested resource's `userId` does
  // not match the ID of the current user (or if you are not signed in).
  //
  // However, in this case, we overrode this to 'id', so ultimately, the hook
  // will check if the user requesting the resource *is* the resource.
  //
  // In simplest terms: Users can only read their own data, and nobody else's.
  service.beforeRead.listen(auth.restrictToOwner(ownerField: 'id'));

  // `hooks.remove` will remove the given information from the result of a service method
  // if the caller was a *client*. It will not take any effect if the method was called by the server.
  //
  // In this case, we use it to prevent putting users' passwords in plaintext JSON, because if you don't
  // recall, they're not even hashed to begin with!
  //
  // You might consider doing this even if passwords are hashed. If malicious clients can see a hashed password,
  // they may be able to reverse-engineer it.
  service.afterAll(hooks.remove('password'));
}

/// Applies configuration to the `api/notes` service.
configureNotes(Angel app) async {
  var service = app.service('api/notes') as HookedService;

  // As explained above, `auth.restrictToOwner` will prevent users from interacting with the
  // given resource if they do not own it. Hooray for authorization hooks!
  service.before([
    HookedServiceEvent.READ,
    HookedServiceEvent.MODIFIED,
    HookedServiceEvent.UPDATED,
    HookedServiceEvent.REMOVED
  ], auth.restrictToOwner());

  // `auth.queryWithCurrentUser` does exactly what it says it does.
  // It adds the 'id' of the current user to 'query' in the service method
  // `params` as 'userId'. Of course, these keys can be configured.
  //
  // The actual querying in this case is performed by the `MongoService`.
  service.beforeIndexed.listen(auth.queryWithCurrentUser());

  service.beforeCreated.listen(hooks.chainListeners([
    // Validation explained above...
    validateEvent(CREATE_NOTE),
    // The name does not give a hint, but `auth.associateCurrentUser` will
    // take the 'id' of the current user, and add it to the service method's
    // `data` as 'userId'. These keys can be configured, of course.
    //
    // This goes hand in hand with the other authorization hooks, because they use
    // a 'userId' to determine who has access to which resources.
    auth.associateCurrentUser(),
    hooks.addCreatedAt()
  ]));

  // `beforeModify` attaches a listener to `create`, `modify`, and `update`.
  // In all three of these cases, you would want to set an `updatedAt` field,
  // so why not kill three birds with one stone?
  service.beforeModify(hooks.addUpdatedAt());
}
