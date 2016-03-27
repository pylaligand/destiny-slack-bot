// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'slack_command_handler.dart';
import 'slack_format.dart';

const _OPTION_XBL = 'xbl';
const _OPTION_PSN = 'psn';

/// Looks up online clan members.
class OnlineHandler extends SlackCommandHandler {
  final log = new Logger('OnlineHandler');
  final String _clanId;

  OnlineHandler(this._clanId);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params['bungie_client'];
    final option = params['text'];
    log.info('@${params['user_name']} viewing online guardians on $option');
    if (option != _OPTION_XBL && option != _OPTION_PSN) {
      log.warning('Invalid platform identifier');
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
    log.info('${nowPlaying.length} online');
    nowPlaying.forEach((member) => log.info(' - $member'));
    if (nowPlaying.isEmpty) {
      final text = 'No guardian online';
      return createAttachmentResponse(
          {'color': '#ff0000', 'text': text, 'fallback': text});
    } else {
      final List<String> names =
          nowPlaying.map((member) => member.gamertag).toList();
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final content = '```${names.join('\n')}```';
      return createTextResponse(content);
    }
  }
}
