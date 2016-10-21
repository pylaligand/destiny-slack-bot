// Copyright (c) 2016 P.Y. Laligand

import 'package:timezone/standalone.dart';

import '../actions/action.dart' as action;
import '../the_hundred_client.dart';
import 'dates.dart' as dates;

Map generateGameAttachment(Game game, TZDateTime now,
    {String color: null, bool withActions: false, bool summary: false}) {
  final result = {};
  final date =
      _formatDate(new TZDateTime.from(game.startDate, now.location), now);
  result['fallback'] = '${game.title} - $date';
  if (color != null) {
    result['color'] = color;
  }
  result['author_name'] = date;
  result['title'] = game.title;
  result['title_link'] = game.url;
  result['text'] = game.description;
  if (!summary) {
    final isPlaying = (Player player) => !player.inReserve;
    final fields = [
      _createField('Creator', game.creator),
      _createField('Platform', game.platformLabel),
      _createField('Spots', (game.teamSize - game.playerCount).toString()),
      _createField(
          'Players',
          game.players.any(isPlaying)
              ? _listPlayers(game.players.where(isPlaying),
                  total: game.playerCount)
              : 'none')
    ];
    final isReserve = (Player player) => player.inReserve;
    if (game.players.any(isReserve)) {
      fields.add(_createField(
          'Reserves', _listPlayers(game.players.where(isReserve))));
    }
    result['fields'] = fields;
  }
  if (withActions) {
    result['actions'] = [
      {
        'name': 'show',
        'text': 'Show this game',
        'type': 'button',
        'value': game.id
      }
    ];
    result['callback_id'] = action.SHOW_LFG_GAME;
  }
  return result;
}

/// Generates a user-friendly string representing the given date.
String _formatDate(TZDateTime date, TZDateTime now) {
  final day = dates.formatDay(date, now);
  final hour = date.hour % 12;
  final amPm = date.hour < 12 ? 'am' : 'pm';
  return '$day ${hour != 0 ? hour : 12}:${date.minute.toString().padLeft(2, '0')}$amPm ${date.timeZoneName}';
}

/// Create a field component for an attachment.
Map _createField(String title, String content, {bool short: false}) =>
    {'title': title, 'value': content, 'short': short};

/// Generates a list of players in a game.
String _listPlayers(Iterable<Player> players, {int total: 0}) =>
    players.map((player) => player.gamertag).join('\n') +
    ((total > players.length) ? '\n+ ${total - players.length}' : '');
