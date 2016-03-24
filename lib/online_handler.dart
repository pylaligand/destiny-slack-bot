// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

import 'bungie_client.dart';
import 'slack_format.dart';

const _OPTION_XBL = 'xbl';
const _OPTION_PSN = 'psn';

/// Looks up online clan members.
class OnlineHandler extends Routeable {
  final String _clanId;

  OnlineHandler(this._clanId);

  @override
  createRoutes(Router router) {
    router.post('/', _handle);
  }

  Future<shelf.Response> _handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params['bungie_client'];
    final option = params['text'];
    print('@${params['user_name']} viewing online guardians on $option');
    if (option != _OPTION_XBL && option != _OPTION_PSN) {
      print('Invalid platform identifier');
      return createResponse('Err, that is not a valid platform!',
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
    print('${nowPlaying.length} online');
    nowPlaying.forEach((member) => print(' - $member'));
    final List<String> names =
        nowPlaying.map((member) => member.gamertag).toList();
    names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final content = '```${names.join('\n')}```';
    return createResponse(content);
  }
}
