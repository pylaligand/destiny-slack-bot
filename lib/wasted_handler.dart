// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math' show Random;

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'clients/wasted_on_destiny_client.dart';
import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';
import 'utils/players.dart' as players;

// TODO(pylaligand): move this constant to base class.
const _OPTION_HELP = 'help';

/// Displays time "wasted" on Destiny.
class WastedHandler extends SlackCommandHandler {
  final _log = new Logger('WastedHandler');

  final _random = new Random();

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params[param.BUNGIE_CLIENT];
    final String userName = params[param.SLACK_USERNAME];
    final text = params[param.SLACK_TEXT];
    if (text == _OPTION_HELP) {
      _log.info('@$userName needs help');
      return createTextResponse(
          'Looks up a given player\'s time well spent on Destiny',
          private: true);
    }

    _log.info('@$userName looking up "$text"');
    final player = await players.lookUp(client, userName, text);
    final gamertag = player.gamertag;
    if (!player.wasFound) {
      _log.warning('Could not identify gamertag "$gamertag".');
      return createTextResponse('Unable to identify "gamertag"', private: true);
    }
    final id = player.id;
    _log.info('Found id $id for $gamertag');

    final result = await (new WastedOnDestinyClient()
        .getHoursWellEnjoyed(gamertag, id.onXbox));
    if (result.isValid) {
      final hours = result.hours;
      final url = result.url;
      _log.info('$hours hours played.');
      final flavorText = _getFlavorText(hours);
      return createTextResponse(
          '$gamertag has spent <$url|*$hours* hours> enjoying Destiny - or about $flavorText',
          expandLinks: false);
    } else {
      _log.warning('Could not find stat...');
      return createTextResponse('Could not find stats for $gamertag',
          private: true);
    }
  }

  String _getFlavorText(int hours) {
    switch (_random.nextInt(3)) {
      case 0:
        return '${(hours / 1.5).round()} soccer games';
      case 1:
        return '${(hours / 0.83).round()} episodes of House of Cards';
      default:
        return '${(hours / 2.5).round()} graduation ceremonies';
    }
  }
}
