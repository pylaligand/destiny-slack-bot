// Copyright (c) 2016 P.Y. Laligand

import 'package:quiver/core.dart';

/// Represents a player's character.
class Character {
  final String id;
  final String clazz;
  final DateTime lastPlayed;

  const Character(this.id, this.clazz, this.lastPlayed);

  @override
  String toString() => 'Character{$id, $clazz}';
}

/// Base class for the various types of IDs in the Bungie API.
class Id {
  /// The type of id.
  final String type;

  /// The actual id.
  final String token;

  const Id(this.type, this.token);

  @override
  String toString() => '{$type:$token}';
}

/// The Destiny id.
class DestinyId extends Id {
  const DestinyId(bool onXbox, String token) : super(onXbox ? '1' : '2', token);

  /// Whether the player is on Xbox or Playstation.
  bool get onXbox => type == '1';

  @override
  bool operator ==(other) =>
      other is DestinyId && onXbox == other.onXbox && token == other.token;

  @override
  int get hashCode => hash2(onXbox, token);
}

/// The Bungie identifier, independent of gaming platform.
class BungieId extends Id {
  const BungieId(String token) : super('254', token);
}

/// A member of a clan.
class ClanMember {
  /// Username on bungie.net.
  final String bungieUserName;

  /// The Bungie identifier.
  final BungieId id;

  /// Gaming platform id.
  final String gamertag;

  /// Whether the player is on Xbox or Playstation.
  final bool onXbox;

  const ClanMember(this.bungieUserName, this.id, this.gamertag, this.onXbox);

  @override
  String toString() => '$bungieUserName[$id]';
}
