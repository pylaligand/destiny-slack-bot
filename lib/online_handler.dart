// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
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
    final timeLimit = new DateTime.now().subtract(const Duration(minutes: 10));
    await Future.wait(members.map((member) async {
      final character = await client.getLastPlayedCharacter(member.id);
      if (character != null && character.lastPlayed.isAfter(timeLimit)) {
        nowPlaying.add(member);
      }
    }));
    _log.info('${nowPlaying.length} online');
    nowPlaying.forEach((member) => _log.info(' - $member'));
    if (nowPlaying.isEmpty) {
      final text = 'No guardian online';
      return createAttachmentResponse(
          {'color': '#ff0000', 'text': text, 'fallback': text});
    } else {
      nowPlaying.sort((a, b) =>
          a.gamertag.toLowerCase().compareTo(b.gamertag.toLowerCase()));
      final content = nowPlaying
          .map((member) => '<${_getProfileUrl(member)}|${member.gamertag}>')
          .join('\n');
      return createTextResponse('```$content```');
    }
  }

  // Returns the profile URL for the given clan member.
  Uri _getProfileUrl(ClanMember member) {
    if (member.onXbox) {
      return new Uri.https(
          'account.xbox.com', 'en-US/Profile', {'gamerTag': member.gamertag});
    } else {
      return new Uri.https('my.playstation.com', member.gamertag);
    }
  }
}
