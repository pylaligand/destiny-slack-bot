// Copyright (c) 2016 P.Y. Laligand

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

/// Handles authentication responses when registering a Slack app.
class AuthHandler extends Routeable {
  final _log = new Logger('AuthHandler');

  @override
  createRoutes(Router router) {
    router.get('/', _handleRequest);
  }

  shelf.Response _handleRequest(shelf.Request request) {
    _log.info(request.requestedUri);
    return new shelf.Response.ok('Works for us!');
  }
}
