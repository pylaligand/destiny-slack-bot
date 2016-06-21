// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'bungie_database.dart';
import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';

const _OPTION_XBL = 'xbl';
const _OPTION_PSN = 'psn';

/// Looks up online clan members.
class OnlineHandler extends SlackCommandHandler {
  final _log = new Logger('OnlineHandler');
  final String _clanId;

  OnlineHandler(this._clanId);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params[param.BUNGIE_CLIENT];
    final option = params[param.SLACK_TEXT];
    _log.info(
        '@${params[param.SLACK_USERNAME]} viewing online guardians on $option');
    if (option != _OPTION_XBL && option != _OPTION_PSN) {
      _log.warning('Invalid platform identifier');
      return createTextResponse('Err, that is not a valid platform!',
          private: true);
    }
    final members = await client.getClanRoster(_clanId, option == _OPTION_XBL);
    final nowPlaying = <ClanMember>[];
    final activities = <DestinyId, Activity>{};
    final timeLimit = new DateTime.now().subtract(const Duration(minutes: 10));
    final BungieDatabase database = params[param.BUNGIE_DATABASE];
    await database.connect();
    try {
      await Future.wait(members.map((member) async {
        final character = await client.getLastPlayedCharacter(member.id);
        if (character == null || character.lastPlayed.isBefore(timeLimit)) {
          return;
        }
        nowPlaying.add(member);
        final reference = await client.getLastCharacterActivity(character);
        if (reference != null) {
          activities[member.id] = await database.getActivity(reference);
        }
      }));
    } finally {
      database.close();
    }
    _log.info('${nowPlaying.length} online');
    nowPlaying.forEach((member) => _log.info(' - $member'));
    if (nowPlaying.isEmpty) {
      final text = 'No guardian online';
      return createAttachmentResponse(
          {'color': '#ff0000', 'text': text, 'fallback': text});
    } else {
      nowPlaying.sort((a, b) =>
          a.gamertag.toLowerCase().compareTo(b.gamertag.toLowerCase()));
      final maxNameLength =
          nowPlaying.map((member) => member.gamertag.length).reduce(math.max);
      final content = nowPlaying.map((member) {
        final url = _getProfileUrl(member);
        final name = member.gamertag;
        final buffer = new StringBuffer('<$url|$name>');
        final activity = activities[member.id];
        if (activity != null) {
          final blanks = maxNameLength - name.length;
          buffer.write(''.padRight(blanks));
          buffer.write(' | ');
          if (activity.name.startsWith(activity.type)) {
            buffer.write(activity.name);
          } else {
            buffer.write('${activity.type} - ${activity.name}');
          }
        }
        return buffer.toString();
      }).join('\n');
      return createTextResponse('```$content```');
    }
  }

  /// Returns the profile URL for the given clan member.
  Uri _getProfileUrl(ClanMember member) {
    if (member.onXbox) {
      return new Uri.https(
          'account.xbox.com', 'en-US/Profile', {'gamerTag': member.gamertag});
    } else {
      return new Uri.https('my.playstation.com', member.gamertag);
    }
  }
}
