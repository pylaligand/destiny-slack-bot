// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart';

import 'utils/json.dart' as json;

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

  /// Desired team size.
  final int teamSize;

  /// Current team size.
  /// Might be greater than the size of [players] if unregistered players were
  /// declared.
  final int playerCount;
  final List<Player> players;

  const Game(
      this.id,
      this.groupId,
      this.title,
      this.description,
      this.creator,
      this.startDate,
      this.platform,
      this.teamSize,
      this.playerCount,
      this.players);

  /// Returns the URL of the gaming session.
  String get url => 'https://www.the100.io/gaming_sessions/$id';

  String get platformLabel => platform == Platform.xbox ? 'XB' : 'PS';

  @override
  String toString() => '$creator | $title | $startDate';

  @override
  bool operator ==(Object other) => other is Game && id == other.id;

  @override
  int get hashCode => id.hashCode;
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

  /// Returns the URL of the game creation page for the group.
  String get gameCreationUrl =>
      'https://www.the100.io/gaming_sessions/new?group_id=$_groupId';

  /// Returns the location used to set the timezone on dates.
  Location get location => _location;

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
            game['team_size'],
            game['primary_users_count'],
            game['confirmed_sessions']
                .map((player) => new Player(
                    player['user']['gamertag'], player['reserve_spot']))
                .toList()))
        .toList();
  }

  /// Returns the response to a URL request as parsed JSON, or null if the
  /// request failed.
  Future<dynamic> _getJson(String url) async {
    return json.get(url, _log,
        headers: {'Authorization': 'Token token="$_authToken"'});
  }
}
