// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart';

/// The platform a game is scheduled on.
enum Platform { xbox, playstation }

/// A participant in a game.
class Player {
  final String gamertag;
  final bool inReserve;

  const Player(this.gamertag, this.inReserve);
}

/// A gaming session.
class Game {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final String creator;
  final TZDateTime startDate;
  final Platform platform;
  final List<Player> players;

  const Game(this.id, this.groupId, this.title, this.description, this.creator,
      this.startDate, this.platform, this.players);

  @override
  String toString() => '$creator - $title - $startDate';
}

/// Client for the the100.io API.
class TheHundredClient {
  final _log = new Logger('TheHundredClient');
  final String _authToken;
  final String _groupId;
  final Location _location;

  TheHundredClient(this._authToken, this._groupId)
      : _location = getLocation('America/Los_Angeles');

  static const _BASE = 'https://www.the100.io/api/v1';

  /// Returns the id of the the100 group.
  String get groupId => _groupId;

  /// Returns the list of all upcoming games in the group.
  Future<List<Game>> getAllGames() async {
    final url = '$_BASE/groups/$_groupId/gaming_sessions';
    final json = await _getJson(url);
    return json
        .map((game) => new Game(
            game['id'],
            _groupId,
            game['category'],
            game['name'],
            game['creator_gamertag'],
            TZDateTime.parse(_location, game['start_time']),
            game['platform'].startsWith('xbox')
                ? Platform.xbox
                : Platform.playstation,
            game['confirmed_sessions']
                .map((player) => new Player(
                    player['user']['gamertag'], player['reserve_spot']))
                .toList()))
        .toList();
  }

  /// Returns the response to a URL request as parsed JSON, or null if the
  /// request failed.
  dynamic _getJson(String url) async {
    final body = await http.read(url,
        headers: {'Cookie': 'auth_token=$_authToken'}).catchError((e, _) {
      _log.warning('Failed request: $e');
      return null;
    });
    if (body == null) {
      return null;
    }
    try {
      return JSON.decode(body);
    } on FormatException catch (e) {
      _log.warning('Failed to decode content: $e');
      return null;
    }
  }
}
