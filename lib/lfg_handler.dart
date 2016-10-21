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
import 'utils/game_format.dart';

const _OPTION_HELP = 'help';
const _OPTION_XBL = 'xbl';
const _OPTION_PSN = 'psn';
const _OPTION_FILTER = 'filter';

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
    return createAttachmentsResponse(attachments, private: shouldFilter);
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

  /// Generates an attachment representing a game.
  Map _generateAttachment(
          List<Game> games, int index, TZDateTime now, bool shouldFilter) =>
      generateGameAttachment(games[index], now,
          color: ATTACHMENT_COLORS[index % ATTACHMENT_COLORS.length],
          withActions: shouldFilter);
}
