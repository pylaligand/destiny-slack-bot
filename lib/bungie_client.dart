// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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

/// Represents a player's character.
class Character {
  final String id;
  final String clazz;

  Character(this.id, this.clazz);

  @override
  String toString() => 'Character{$id, $clazz}';
}

/// Client for the Bungie REST API.
class BungieClient {
  final String _apiKey;

  BungieClient(this._apiKey);

  /// Returns the Destiny id ("membershipId") of the player named [gamertag].
  ///
  /// Will look up on XNL or PSN depending on [onXbox].
  Future<String> getDestinyId(String gamertag, bool onXbox) async {
    final type = onXbox ? '1' : '2';
    final url = '$_BASE/Destiny/SearchDestinyPlayer/$type/$gamertag';
    final data = await _getJson(url);
    if (data['ErrorCode'] != 1 ||
        data['Response'] == null ||
        data['Response'].isEmpty ||
        data['Response'][0] == null) {
      return null;
    }
    return data['Response'][0]['membershipId'];
  }

  /// Returns the last character the given player played with.
  Future<Character> getLastPlayedCharacter(
      String destinyId, bool onXbox) async {
    final type = onXbox ? '1' : '2';
    final url = '$_BASE/User/GetBungieAccount/$destinyId/$type/';
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
        characterData['characterId'], characterData['classHash'].toString());
  }

  /// Returns the equipped subclass for the given character.
  Future<String> getEquippedSubclass(String destinyId, bool onXbox,
      String characterId, String characterClass) async {
    final type = onXbox ? '1' : '2';
    final url =
        '$_BASE/Destiny/$type/Account/$destinyId/Character/$characterId/Inventory/Summary/';
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

  dynamic _getJson(String url) async {
    var body = await http.read(url, headers: {'X-API-Key': this._apiKey});
    return JSON.decode(body);
  }
}
