// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:timezone/standalone.dart';

import 'clients/slack_client.dart';
import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';
import 'the_hundred_client.dart';
import 'utils/dates.dart' as dates;

const _OPTION_HELP = 'help';
const _OPTION_XBL = 'xbl';
const _OPTION_PSN = 'psn';
const _OPTION_FILTER = 'filter';

const _COLORS = const ['#4285f4', '#f4b400', '#0f9d58', '#db4437'];

enum _Platform { xbox, playstation, both }

/// Exposes LFG functionality.
class LfgHandler extends SlackCommandHandler {
  final _log = new Logger('LfgHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final TheHundredClient theHundredClient = params[param.THE_HUNDRED_CLIENT];
    final SlackClient slackClient = params[param.SLACK_CLIENT];
    final String options = params[param.SLACK_TEXT];
    final username = params[param.SLACK_USERNAME];
    final optionList = options.split(new RegExp(r'\s+'));
    if (optionList.first == _OPTION_HELP) {
      _log.info('@$username needs help');
      return createTextResponse('View upcoming gaming sessions', private: true);
    }
    final shouldFilter = optionList.last == _OPTION_FILTER;
    final platform = _extractPlatform(optionList.first);
    _log.info('@$username looking up games');
    final games =
        _filterByPlatform(await theHundredClient.getAllGames(), platform);
    _log.info('${games.length} game(s)');
    games.forEach(_log.info);
    if (games.isEmpty) {
      return createErrorAttachment(
          'No game scheduled, wanna <${theHundredClient.gameCreationUrl}|create one>?');
    }
    final userId = params[param.SLACK_USER_ID];
    final timezone = await slackClient.getUserTimezone(userId);
    final location =
        timezone != null ? getLocation(timezone) : theHundredClient.location;
    final now = new TZDateTime.now(location);
    final attachments = new Iterable.generate(games.length)
        .map((index) => _generateAttachment(games, index, now, shouldFilter))
        .toList();
    return createAttachmentsResponse(attachments);
  }

  /// Filters games by platform based on user input.
  List<Game> _filterByPlatform(List<Game> games, _Platform platform) {
    switch (platform) {
      case _Platform.xbox:
        _log.info('Focusing on Xbox');
        return games.where((game) => game.platform == Platform.xbox).toList();
      case _Platform.playstation:
        _log.info('Focusing on Playstation');
        return games
            .where((game) => game.platform == Platform.playstation)
            .toList();
      default:
        return games;
    }
  }

  /// Generates an attachment representing a game.
  Map _generateAttachment(
      List<Game> games, int index, TZDateTime now, bool shouldFilter) {
    final game = games[index];
    final result = {};
    final date =
        _formatDate(new TZDateTime.from(game.startDate, now.location), now);
    result['fallback'] = '${game.title} - $date';
    result['color'] = _COLORS[index % _COLORS.length];
    result['author_name'] = date;
    result['title'] = game.title;
    result['title_link'] = game.url;
    result['text'] = game.description;
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
    if (shouldFilter) {
      result['actions'] = [
        {
          'name': 'show_lfg_game',
          'text': 'Show this game',
          'type': 'button',
          'value': index.toString()
        }
      ];
      result['callback_id'] = 'lfg_gamez';
    }
    return result;
  }

  /// Identifies the targeted platform.
  _Platform _extractPlatform(String option) {
    switch (option) {
      case _OPTION_XBL:
        return _Platform.xbox;
      case _OPTION_PSN:
        return _Platform.playstation;
      default:
        return _Platform.both;
    }
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
}
