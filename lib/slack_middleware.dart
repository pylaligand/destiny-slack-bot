// Copyright (c) 2016 P.Y. Laligand

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'clients/slack_client.dart';
import 'context_params.dart' as param;

/// Verifies that requests come from Slack and makes the content of these
/// requests more accessible to handlers.
class SlackMiddleware {
  static final _log = new Logger('SlackMiddleware');

  static shelf.Middleware get(
          List<String> tokens, bool useDelayedResponses, String authToken) =>
      (shelf.Handler handler) {
        return (shelf.Request request) async {
          if (request.method != 'POST') {
            // Only perform token verification on POST requests.
            return handler(request);
          }
          final contentType = request.headers['content-type'];
          if (contentType != 'application/x-www-form-urlencoded') {
            _log.warning('Invalid content type: $contentType');
            return new shelf.Response.notFound('Invalid content type');
          }
          final body = await request.readAsString();
          final params = Uri.splitQueryString(Uri.decodeFull(body));
          final requestToken = params['token'];
          if (!tokens.contains(requestToken)) {
            _log.warning('Invalid token: $requestToken');
            return new shelf.Response.forbidden('Invalid token');
          }
          final Map<String, String> context = {
            param.SLACK_CLIENT: new SlackClient(authToken),
            param.USE_DELAYED_RESPONSES: useDelayedResponses
          };
          params.forEach((key, value) => context['slack_param_$key'] = value);
          return handler(request.change(context: context));
        };
      };
}
