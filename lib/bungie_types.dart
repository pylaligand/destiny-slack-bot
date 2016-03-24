// Copyright (c) 2016 P.Y. Laligand

/// Represents a player's character.
class Character {
  final String id;
  final String clazz;
  final DateTime lastPlayed;

  Character(this.id, this.clazz, this.lastPlayed);

  @override
  String toString() => 'Character{$id, $clazz}';
}

/// Base class for the various types of IDs in the Bungie API.
class Id {
  /// The type of id.
  final String type;

  /// The actual id.
  final String token;

  Id(this.type, this.token);

  @override
  String toString() => '{$type:$token}';
}

/// The Destiny id.
class DestinyId extends Id {
  DestinyId(bool onXbox, String token) : super(onXbox ? '1' : '2', token);

  /// Whether the player is on Xbox or Playstation.
  bool get onXbox => type == '1';
}

/// The Bungie identifier, independent of gaming platform.
class BungieId extends Id {
  BungieId(String token) : super('254', token);
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

  ClanMember(this.bungieUserName, this.id, this.gamertag, this.onXbox);

  @override
  String toString() => '$bungieUserName[$id]';
}
