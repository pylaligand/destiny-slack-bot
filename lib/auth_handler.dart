// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

import 'utils/json.dart' as json;

/// Handles authentication responses when registering a Slack app.
class AuthHandler extends Routeable {
  final _log = new Logger('AuthHandler');

  final String _clientId;
  final String _clientSecret;

  AuthHandler(this._clientId, this._clientSecret);

  @override
  createRoutes(Router router) {
    router.get('/', _handleRequest);
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    _log.info(request.requestedUri);
    final code = request.url.queryParameters['code'];
    final url = new Uri.https('slack.com', 'api/oauth.access',
        {'client_id': _clientId, 'client_secret': _clientSecret, 'code': code});
    final data = await json.get(url.toString(), _log);
    _log.info('Authenticated: ${data["scope"]}');
    return new shelf.Response.ok('Works for us!');
  }
}
