// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'bungie_types.dart';

export 'bungie_types.dart';

/// Base URL for API calls.
const _BASE = 'http://www.bungie.net/Platform';

/// Client for the Bungie REST API.
class BungieClient {
  final String _apiKey;

  BungieClient(this._apiKey);

  /// Attempts to fetch the Destiny id of the player identified by [gamertag].
  ///
  /// If [onXbox] is specified, this method will look for the player on the
  /// appropriate platform, return the Destiny id is found or null otherwise.
  ///
  /// if [onXbox] is not specified, this method will look for the player on both
  /// platforms. If the player is found, the return value will be a pair
  /// consisting of the Destiny id and a boolean representing the platform similar
  /// to [onXbox]. Otherwise null is returned.
  Future<DestinyId> getDestinyId(String gamertag, {bool onXbox}) async {
    return onXbox != null
        ? await _getDestinyId(gamertag, onXbox)
        : (await _getDestinyId(gamertag, true /* Xbox */) ??
            await _getDestinyId(gamertag, false /* Playstation */));
  }

  /// Returns the Destiny id of the player named [gamertag].
  ///
  /// Will look up on XBL or PSN depending on [onXbox].
  Future<DestinyId> _getDestinyId(String gamertag, bool onXbox) async {
    final type = onXbox ? '1' : '2';
    final url = '$_BASE/Destiny/SearchDestinyPlayer/$type/$gamertag';
    final data = await _getJson(url);
    if (!_hasValidResponse(data) ||
        data['Response'].isEmpty ||
        data['Response'][0] == null) {
      return null;
    }
    return new DestinyId(onXbox, data['Response'][0]['membershipId']);
  }

  /// Returns a reference to the given player's current activity, or null if the
  /// player is not online.
  Future<ActivityReference> getCurrentActivity(DestinyId id) async {
    final url = '$_BASE/Destiny/${id.type}/Account/${id.token}/Summary';
    final data = await _getJson(url);
    if (!_hasValidResponse(data) ||
        data['Response']['data'] == null ||
        data['Response']['data']['characters'] == null) {
      return null;
    }
    final List<dynamic> characters = data['Response']['data']['characters'];
    final activityHash = characters
        .map((character) => character['characterBase']['currentActivityHash'])
        .firstWhere((hash) => hash != 0, orElse: () => null);
    return activityHash != null ? new ActivityReference(activityHash) : null;
  }

  /// Returns the last character the given player played with.
  Future<Character> getLastPlayedCharacter(DestinyId id) async {
    final url = '$_BASE/User/GetBungieAccount/${id.token}/${id.type}/';
    final data = await _getJson(url);
    if (!_hasValidResponse(data) ||
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
        id,
        characterData['characterId'],
        characterData['classHash'].toString(),
        DateTime.parse(characterData['dateLastPlayed']));
  }

  /// Returns a reference to the last game completed with the given character.
  Future<ActivityReference> getCharacterLastCompletedActivity(
      Character character) async {
    final id = character.owner;
    final url =
        '$_BASE/Destiny/Stats/ActivityHistory/${id.type}/${id.token}/${character.id}?mode=None';
    final data = await _getJson(url);
    if (!_hasValidResponse(data) ||
        data['Response']['data'] == null ||
        data['Response']['data']['activities'] == null ||
        data['Response']['data']['activities'].isEmpty ||
        data['Response']['data']['activities'][0] == null) {
      return null;
    }
    final activity = data['Response']['data']['activities'][0];
    final instance = activity['activityDetails']['referenceId'];
    final override = activity['activityDetails']['activityTypeHashOverride'];
    return new ActivityReference.withOverride(instance, override);
  }

  /// Returns the grimoire score of the given player.
  Future<int> getGrimoireScore(Id id) async {
    final url = '$_BASE/User/GetBungieAccount/${id.token}/${id.type}/';
    final data = await _getJson(url);
    if (!_hasValidResponse(data) ||
        data['Response']['destinyAccounts'] == null ||
        data['Response']['destinyAccounts'].isEmpty ||
        data['Response']['destinyAccounts'][0] == null) {
      return null;
    }
    return data['Response']['destinyAccounts'][0]['grimoireScore'];
  }

  /// Returns the inventory for the given character.
  Future<Inventory> getInventory(Id id, String characterId) async {
    final url =
        '$_BASE/Destiny/${id.type}/Account/${id.token}/Character/$characterId/Inventory/Summary/';
    final data = await _getJson(url);
    if (!_hasValidResponse(data) ||
        data['Response']['data'] == null ||
        data['Response']['data']['items'] == null ||
        data['Response']['data']['items'].isEmpty) {
      return null;
    }
    return new Inventory(data['Response']['data']['items']);
  }

  /// Returns the list of members on XBL or PSN for the given clan.
  Future<List<ClanMember>> getClanRoster(String clanId, bool onXbox) async {
    int pageIndex = 0;
    final members = <ClanMember>[];
    while (true) {
      final data = await _getClanRosterPage(clanId, onXbox, pageIndex++);
      if (!_hasValidResponse(data) ||
          data['Response']['results'] == null ||
          data['Response']['results'].isEmpty) {
        continue;
      }
      members.addAll(data['Response']['results'].map((userData) =>
          new ClanMember(new DestinyId(onXbox, userData['membershipId']),
              userData['destinyUserInfo']['displayName'], onXbox)));
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
        '$_BASE/Group/$clanId/ClanMembers/?currentPage=$pageIndex&platformType=$type';
    return await _getJson(url);
  }

  /// Returns the items sold by Xur.
  /// The returned list is empty if Xur is not around, or null if his inventory
  /// could not be retrieved.
  Future<List<XurExoticItem>> getXurInventory() async {
    const url = '$_BASE/Destiny/Advisors/Xur/';
    final data = await _getJson(url);
    if (!_hasValidResponse(data)) {
      return null;
    }
    if (data['Response'].isEmpty) {
      return const <XurExoticItem>[];
    }
    final Map<String, dynamic> exoticItems = data['Response']['data']
            ['saleItemCategories']
        .firstWhere((Map<String, dynamic> category) =>
            category['categoryTitle'] == 'Exotic Gear');
    return exoticItems['saleItems']
        .map((Map<String, dynamic> item) {
          if (!item['item']['isEquipment']) {
            // Ignore exotic engrams.
            return null;
          }
          return new XurExoticItem(
              new ItemId(item['item']['itemHash']),
              item['item']['primaryStat']['statHash'] ==
                  3897883278 /* defense */);
        })
        .where((item) => item != null)
        .toList();
  }

  dynamic _getJson(String url) async {
    final body = await http.read(url, headers: {'X-API-Key': this._apiKey});
    try {
      return JSON.decode(body);
    } on FormatException catch (_) {
      return null;
    }
  }

  bool _hasValidResponse(dynamic json) {
    return json != null && json['ErrorCode'] == 1 && json['Response'] != null;
  }
}
