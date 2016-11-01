// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';
import 'package:timezone/standalone.dart';

import '../actions/action.dart' as actions;
import '../clients/slack_client.dart';
import '../context_params.dart' as param;
import '../slack_format.dart';
import '../the_hundred_client.dart';
import '../utils/game_format.dart';

/// Handles Slack message buttons.
class ActionsHandler extends Routeable {
  final _log = new Logger('ActionsHandler');

  final String _verificationToken;

  ActionsHandler(this._verificationToken);

  @override
  createRoutes(Router router) {
    router.post('/', _handleRequest);
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    final contentType = request.headers['content-type'];
    if (contentType != 'application/x-www-form-urlencoded') {
      _log.warning('Invalid content type: $contentType');
      return new shelf.Response.notFound('Invalid content type');
    }
    final body = await request.readAsString();
    final decodedBody = Uri.splitQueryString(Uri.decodeFull(body));
    final payload = decodedBody['payload'];
    final content = JSON.decode(Uri.decodeFull(payload));
    final requestToken = content['token'];
    if (requestToken != _verificationToken) {
      _log.warning('Invalid token: $requestToken');
      return new shelf.Response.forbidden('Invalid token');
    }
    final context = request.context;
    final Future<shelf.Response> responseFuture =
        new Future(() => _generateResponse(content, context));
    if (context[param.USE_DELAYED_RESPONSES]) {
      responseFuture.then((response) async {
        if (response == null) {
          response = createTextResponse('The Darkness consumed your request...',
              private: true);
        }
        http.post(content['response_url'],
            body: await response.readAsString(),
            headers: {'content-type': 'application/json'});
      });
      return new shelf.Response.ok('All clear');
    } else {
      return await responseFuture;
    }
  }

  Future<shelf.Response> _generateResponse(
      Map<String, dynamic> content, Map<String, Object> context) async {
    final String action = content['callback_id'];
    final String value = content['actions'][0]['value'];
    final String userId = content['user']['id'];
    switch (action) {
      case actions.SHOW_LFG_GAME:
        _log.info('Showing game: $value');
        final TheHundredClient the100Client = context[param.THE_HUNDRED_CLIENT];
        final SlackClient slackClient = context[param.SLACK_CLIENT];
        final game = await the100Client.getGame(value);
        if (game == null) {
          _log.warning('Could not find game');
          return createTextResponse('Could not find game: $value',
              private: true);
        }
        final timezone = await slackClient.getUserTimezone(userId);
        final location =
            timezone != null ? getLocation(timezone) : the100Client.location;
        final now = new TZDateTime.now(location);
        return createAttachmentResponse(generateGameAttachment(game, now,
            color: ATTACHMENT_COLORS[0], withActions: false));

      default:
        _log.warning('Unknown action: $action ($value)');
        return createTextResponse('Unrecognized action!', private: true);
    }
  }
}
