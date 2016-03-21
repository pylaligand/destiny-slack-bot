// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const _BASE = 'http://www.bungie.net/Platform';

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

  dynamic _getJson(String url) async {
    var body = await http.read(url, headers: {'X-API-Key': this._apiKey});
    return JSON.decode(body);
  }
}
