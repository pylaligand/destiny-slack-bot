// Copyright (c) 2016 P.Y. Laligand

import 'dart:io' show Platform;
import 'dart:async' show runZoned;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';

void main() {
  var portEnv = Platform.environment['PORT'];
  var port = portEnv == null ? 9999 : int.parse(portEnv);

  final theRouter = router()
    ..get('/', (_) => new shelf.Response.ok('This is the Destiny bot!'))
    ..get('/trials', (_) => new shelf.Response.ok('Coming soon!'));

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(theRouter.handler);

  runZoned(() {
    print('Serving on $port');
    io.serve(handler, '0.0.0.0', port);
  }, onError: (e, stackTrace) => print('Oh noes! $e $stackTrace'));
}
