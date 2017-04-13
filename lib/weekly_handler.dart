// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_database.dart';
import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';

const _OPTION_HELP = 'help';

/// Displays a list of weekly Destiny activities.
class WeeklyHandler extends SlackCommandHandler {
  final _log = new Logger('WeeklyHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final username = params[param.SLACK_USERNAME];
    if (params[param.SLACK_TEXT] == _OPTION_HELP) {
      _log.info('@$username needs help');
      return createTextResponse('View weekly activities', private: true);
    }
    _log.info('@$username viewing weekly activities');
    final BungieClient client = params[param.BUNGIE_CLIENT];
    final activities = await client.getWeeklyActivities();
    if (activities == null) {
      return createTextResponse(
          ':warning: Unable to fetch weekly activities :warning:');
    }
    final BungieDatabase database = params[param.BUNGIE_DATABASE];
    await database.connect();
    Activity nightfallStrike;
    Activity weeklyCrucible;
    Activity weeklyRaid;
    try {
      nightfallStrike = await database.getActivity(activities.nightfall);
      weeklyCrucible = await database.getActivity(activities.cruciblePlaylist);
      weeklyRaid = await database.getActivity(activities.raid);
    } finally {
      database.close();
    }
    final content = {};
    content['fallback'] = 'On the menu this week...';
    content['fields'] = [
      _createField('Nightfall strike', nightfallStrike.name),
      _createField(
          'Nightfall modifiers', activities.nightfallModifiers.join(', ')),
      _createField('Featured raid', weeklyRaid.name),
      _createField('Raid modifiers', activities.raidModifiers.join(', ')),
      _createField('Court of Oryx Tier 3 boss', _getCooBoss()),
      _createField('Challenge of the Elders modifiers',
          activities.poeModifiers.join(', ')),
      _createField('Weekly Crucible', weeklyCrucible.name),
      _createField('Heroic strikes modifiers',
          activities.heroicStrikeModifiers.join(', '))
    ];
    return createAttachmentResponse(content);
  }

  Map<String, String> _createField(String title, String value) {
    return {'title': title, 'value': value};
  }

  String _getCooBoss() {
    const bosses = const ['Thalnok, Fanatic of Crota', 'Balwur', 'Kagoor'];
    // Date where the boss is known to have been the first of the list.
    // Note that there was a schedule shift when update 2.3.0 was introduced,
    // hence the use of a date (much) later that TTK's release date.
    final baseDate = new DateTime.utc(2016, 6, 14, 8);
    final now = new DateTime.now().toUtc();
    final durationWeeks = now.difference(baseDate).inDays / 7;
    final index = durationWeeks.floor() % 3;
    return bosses[index];
  }
}
