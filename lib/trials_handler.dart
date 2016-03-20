// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

/// Handles request for Trials of Osiris information.
class TrialsHandler extends Routeable {
  @override
  createRoutes(Router router) {
    router.post('trials', _handle);
  }

  Future<shelf.Response> _handle(shelf.Request request) async {
    final params = request.context;
    final String user = params['user_name'];
    return new shelf.Response.ok('Coming soon, $user!');
  }
}
