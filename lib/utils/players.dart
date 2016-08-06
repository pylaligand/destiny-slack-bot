// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:bungie_client/bungie_client.dart';

/// Returns a gamertag to look for based on some request parameters.
String _getGamertag(String userName, String text) {
  if (text == null || text.isEmpty) {
    return userName;
  }
  if (text[0] == '@') {
    return text.substring(1);
  }
  return text;
}

/// A player found via [lookUp].
class Player {
  final String gamertag;

  /// null if the player could not be found.
  final DestinyId id;

  const Player(this.gamertag, this.id);

  bool get wasFound => id != null;
}

/// Attempts to resolve a Destiny id based on the Slack user issuing a command
/// and the text they entered.
Future<Player> lookUp(BungieClient client, String userName, String text) async {
  final gamertag = _getGamertag(userName, text);
  final directId = await client.getDestinyId(gamertag);
  if (directId != null) {
    return new Player(gamertag, directId);
  }
  if (!gamertag.contains('_')) {
    return new Player(gamertag, null);
  }
  final alternateGamertag = gamertag.replaceAll('_', ' ');
  return new Player(
      alternateGamertag, await client.getDestinyId(alternateGamertag));
}
