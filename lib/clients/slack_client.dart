// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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
  dynamic _getJson(Uri url) async {
    final body = await http.read(url).catchError((e, _) {
      _log.warning('Failed request: $e');
      return null;
    });
    if (body == null) {
      _log.warning('Empty response');
      return null;
    }
    try {
      final json = JSON.decode(body);
      if (!json['ok']) {
        _log.warning('Error in response: ${json['error']}');
        return null;
      }
      return json;
    } on FormatException catch (e) {
      _log.warning('Failed to decode content: $e');
      return null;
    }
  }
}
