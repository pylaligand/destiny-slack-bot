// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';

import '../utils/json.dart' as json;

/// Client for the Slack API.
class SlackClient {
  final _log = new Logger('SlackClient');
  final String _token;

  SlackClient(this._token);

  /// Posts a message to a channel.
  Future<bool> sendMessage(String message, String channel) async {
    final content = {
      'channel': channel,
      'as_user': 'true',
      'text': message,
      'unfurl_links': 'false',
      'unfurl_media': 'false'
    };
    final url = _getUrl('chat.postMessage', content);
    final json = await _getJson(url);
    return json != null;
  }

  /// Retrieves a user's timezone, or null if the user could not be found.
  Future<String> getUserTimezone(String id) async {
    final url = _getUrl('users.info', {'user': id});
    final json = await _getJson(url);
    return json != null ? json['user']['tz'] : null;
  }

  /// Returns a URL encoding the given parameters.
  Uri _getUrl(String method, [Map content]) {
    final params = content ?? {};
    params['token'] = _token;
    return new Uri.https('slack.com', 'api/$method', params);
  }

  /// Requests JSON data from the given URL.
  /// Returns null if the request failed.
  Future<dynamic> _getJson(Uri url) async {
    final result = await json.get(url.toString(), _log);
    if (!result['ok']) {
      _log.warning('Error in response: ${result['error']}');
      return null;
    }
    return result;
  }
}
