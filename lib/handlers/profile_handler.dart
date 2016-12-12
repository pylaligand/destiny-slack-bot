// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../clients/destiny_trials_report_client.dart';
import '../context_params.dart' as param;
import '../slack_command_handler.dart';
import '../slack_format.dart';
import '../utils/players.dart' as players;

const _OPTION_HELP = 'help';

const _ID_RAID_WOM_NM = 260765522;
const _ID_RAID_WOM_HM = 1387993552;

/// Exposes relevant data about a given player.
class ProfileHandler extends SlackCommandHandler {
  final _log = new Logger('ProfileHandler');

  final DestinyTrialsReportClient _dtrClient = new DestinyTrialsReportClient();

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params[param.BUNGIE_CLIENT];
    final String userName = params[param.SLACK_USERNAME];
    final text = params[param.SLACK_TEXT];
    if (text == _OPTION_HELP) {
      _log.info('@$userName needs help');
      return createTextResponse('Looks up a given player\'s Destiny stats',
          private: true);
    }

    _log.info('@$userName looking up "$text"');
    final player = await players.lookUp(client, userName, text);
    final gamertag = player.gamertag;
    if (!player.wasFound) {
      _log.warning('Could not identify gamertag "$gamertag".');
      return createTextResponse('Unable to identify "$gamertag"',
          private: true);
    }
    final id = player.id;
    _log.info('Found id $id for $gamertag');

    final profile = await client.getPlayerProfile(id);
    int womNormalCount = 0;
    int womHardCount = 0;
    await Future.forEach(profile.characters, (character) async {
      final completions = await client.getCharacterRaidCompletions(character);

      int _countActivity(List<ActivityReference> activities, int id) =>
          activities.where((activity) => activity.id == id).length;
      final className = getCharacterClassName(character.clazz);
      final womNormal = _countActivity(completions, _ID_RAID_WOM_NM);
      final womHard = _countActivity(completions, _ID_RAID_WOM_HM);
      _log.info('$className: $womNormal NM, $womHard HM');
      womNormalCount += womNormal;
      womHardCount += womHard;
    });

    final lighthouseCount = await _dtrClient.getLighthouseTripCount(id.token);

    final content = {};
    content['title'] = player.gamertag;
    content['title_link'] = client.getPlayerProfileUrl(id);
    content['fallback'] = 'Profile for ${player.gamertag}';
    content['fields'] = [
      _createField('Grimoire', profile.grimoire.toString()),
      _createField(
          'Characters',
          profile.characters
              .map((character) => getCharacterClassName(character.clazz))
              .join(', ')),
      _createField('Wrath of Machine - Normal', '$womNormalCount completions'),
      _createField('Wrath of Machine - Hard', '$womHardCount completions'),
      _createField('Flawless Trials of Osiris', lighthouseCount.toString()),
    ];
    return createAttachmentResponse(content);
  }

  Map<String, String> _createField(String title, String value) {
    return {'title': title, 'value': value};
  }
}
