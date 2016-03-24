// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'bungie_types.dart';

export 'bungie_types.dart';

/// Base URL for API calls.
const _BASE = 'http://www.bungie.net/Platform';

/// Mappings from class to subclasses to subclass names.
const _SUBCLASSES = const {
  // Hunter
  '671679327': const {
    '2962927168': 'Bladedancer',
    '4143670657': 'Nightstalker',
    '1716862031': 'Gunslinger'
  },
  // Titan
  '3655393761': const {
    '2455559914': 'Striker',
    '2007186000': 'Defender',
    '21395672': 'Sunbreaker'
  },
  // Warlock
  '2271682572': const {
    '1256644900': 'Stormcaller',
    '3828867689': 'Voidwalker',
    '3658182170': 'Sunsinger'
  }
};

/// Client for the Bungie REST API.
class BungieClient {
  final String _apiKey;

  BungieClient(this._apiKey);

  /// Returns the Destiny id of the player named [gamertag].
  ///
  /// Will look up on XBL or PSN depending on [onXbox].
  Future<DestinyId> getDestinyId(String gamertag, bool onXbox) async {
    final type = onXbox ? '1' : '2';
    final url = '$_BASE/Destiny/SearchDestinyPlayer/$type/$gamertag';
    final data = await _getJson(url);
    if (data['ErrorCode'] != 1 ||
        data['Response'] == null ||
        data['Response'].isEmpty ||
        data['Response'][0] == null) {
      return null;
    }
    return new DestinyId(onXbox, data['Response'][0]['membershipId']);
  }

  /// Returns the last character the given player played with.
  Future<Character> getLastPlayedCharacter(Id id) async {
    final url = '$_BASE/User/GetBungieAccount/${id.token}/${id.type}/';
    final data = await _getJson(url);
    if (data['ErrorCode'] != 1 ||
        data['Response'] == null ||
        data['Response']['destinyAccounts'] == null ||
        data['Response']['destinyAccounts'].isEmpty ||
        data['Response']['destinyAccounts'][0] == null ||
        data['Response']['destinyAccounts'][0]['characters'] == null ||
        data['Response']['destinyAccounts'][0]['characters'].isEmpty) {
      return null;
    }
    final characterData = data['Response']['destinyAccounts'][0]['characters']
        .reduce((current, character) {
      final currentPlayedTime = DateTime.parse(current['dateLastPlayed']);
      final lastPlayedTime = DateTime.parse(character['dateLastPlayed']);
      return currentPlayedTime.compareTo(lastPlayedTime) > 0
          ? current
          : character;
    });
    return new Character(
        characterData['characterId'],
        characterData['classHash'].toString(),
        DateTime.parse(characterData['dateLastPlayed']));
  }

  /// Returns the equipped subclass for the given character.
  Future<String> getEquippedSubclass(
      Id id, String characterId, String characterClass) async {
    final url =
        '$_BASE/Destiny/${id.type}/Account/${id.token}/Character/${characterId}/Inventory/Summary/';
    final data = await _getJson(url);
    if (data['ErrorCode'] != 1 ||
        data['Response'] == null ||
        data['Response']['data'] == null ||
        data['Response']['data']['items'] == null ||
        data['Response']['data']['items'].isEmpty) {
      return null;
    }
    final subclasses = _SUBCLASSES[characterClass];
    final subclassHash = data['Response']['data']['items']
        .map((item) => item['itemHash'].toString())
        .firstWhere((hash) => subclasses.containsKey(hash));
    return subclassHash != null ? subclasses[subclassHash] : null;
  }

  /// Returns the list of members on XBL or PSN for the given clan.
  Future<List<ClanMember>> getClanRoster(String clanId, bool onXbox) async {
    int pageIndex = 0;
    final members = <ClanMember>[];
    while (true) {
      final data = await _getClanRosterPage(clanId, onXbox, pageIndex++);
      if (data['ErrorCode'] != 1 ||
          data['Response'] == null ||
          data['Response']['results'] == null ||
          data['Response']['results'].isEmpty) {
        continue;
      }
      members.addAll(data['Response']['results'].map((userData) {
        final user = userData['user'];
        final platformKey = onXbox ? 'xboxDisplayName' : 'psnDisplayName';
        final id = new BungieId(user['membershipId']);
        return new ClanMember(
            user['displayName'], id, user[platformKey], onXbox);
      }));
      if (!data['Response']['hasMore']) {
        break;
      }
    }
    return members;
  }

  /// Fetches a single page of clan roster.
  dynamic _getClanRosterPage(String clanId, bool onXbox, int pageIndex) async {
    final type = onXbox ? '1' : '2';
    final url =
        '$_BASE/Group/${clanId}/Members/?currentPage=${pageIndex}&platformType=${type}';
    return await _getJson(url);
  }

  dynamic _getJson(String url) async {
    var body = await http.read(url, headers: {'X-API-Key': this._apiKey});
    return JSON.decode(body);
  }
}
