// Copyright (c) 2016 P.Y. Laligand

import 'package:quiver/core.dart';

/// Mappings from class to subclasses to subclass names.
const _SUBCLASSES = const {
  // Hunter (671679327)
  2962927168: 'Bladedancer',
  4143670657: 'Nightstalker',
  1716862031: 'Gunslinger',
  // Titan (3655393761)
  2455559914: 'Striker',
  2007186000: 'Defender',
  21395672: 'Sunbreaker',
  // Warlock (2271682572)
  1256644900: 'Stormcaller',
  3828867689: 'Voidwalker',
  3658182170: 'Sunsinger'
};

/// Item buckets for weapons.
const _WEAPON_BUCKETS = const [
  1498876634, // Primary Weapons
  4046403665, // Weapons
  2465295065, // Special Weapons
  953998645 // Heavy Weapons
];

/// Item buckets for armor pieces.
const _ARMOR_BUCKETS = const [
  3003523923, // Armor
  3448274439, // Helmet
  3551918588, // Gauntlet
  14239492, // Chest Armor
  20886954 // Leg armor
];

/// Represents a player's character.
class Character {
  final DestinyId owner;
  final String id;
  final String clazz;
  final DateTime lastPlayed;

  const Character(this.owner, this.id, this.clazz, this.lastPlayed);

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
  /// The Destiny identifier.
  final DestinyId id;

  /// Gaming platform id.
  final String gamertag;

  /// Whether the player is on Xbox or Playstation.
  final bool onXbox;

  const ClanMember(this.id, this.gamertag, this.onXbox);

  @override
  String toString() => '$gamertag[$id]';
}

/// Identifiers for various equipment objects.
class ItemId {
  /// The item's hash value.
  final int hash;

  const ItemId(this.hash);

  @override
  String toString() => hash.toString();
}

/// A character's inventory.
class Inventory {
  /// The raw JSON data.
  final List<dynamic> _items;

  Inventory(this._items);

  /// Returns the weapons in the inventory.
  List<ItemId> get weaponIds => _items
      .where((item) => _WEAPON_BUCKETS.contains(item['bucketHash']))
      .map((item) => new ItemId(item['itemHash']))
      .toList();

  /// Returns the armor pieces in the inventory.
  List<ItemId> get armorIds => _items
      .where((item) => _ARMOR_BUCKETS.contains(item['bucketHash']))
      .map((item) => new ItemId(item['itemHash']))
      .toList();

  /// Returns the equipped subclass.
  String get subclass => _items
      .map((item) => _SUBCLASSES[item['itemHash']])
      .firstWhere((subclass) => subclass != null, orElse: () => null);
}

/// An exotic item (armor or weapon) sold by Xur.
class XurExoticItem {
  final ItemId id;

  /// True if the item is an armor piece - otherwise it's a weapon.
  final bool isArmor;

  const XurExoticItem(this.id, this.isArmor);
}

/// The character classes.
enum Class { TITAN, HUNTER, WARLOCK }

/// Maps database identifiers to classes.
const Map<int, Class> CLASS_MAPPINGS = const {
  0: Class.TITAN,
  1: Class.HUNTER,
  2: Class.WARLOCK,
};

/// The rarity of inventory items.
enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY, EXOTIC }

/// Maps database identifiers to rarity.
const Map<int, Rarity> RARITY_MAPPINGS = const {
  2: Rarity.COMMON,
  3: Rarity.UNCOMMON,
  4: Rarity.RARE,
  5: Rarity.LEGENDARY,
  6: Rarity.EXOTIC
};

/// The various types of weapons.
enum WeaponType {
  // Primary.
  AUTO,
  PULSE,
  SCOUT,
  HAND_CANNON,
  // Special.
  SNIPER,
  FUSION,
  SIDEARM,
  SHOTGUN,
  // Heavy.
  MACHINE_GUN,
  ROCKET_LAUNCHER,
  SWORD
}

/// Maps database identifiers to weapon types.
const Map<int, WeaponType> WEAPON_TYPE_MAPPINGS = const {
  6: WeaponType.AUTO,
  13: WeaponType.PULSE,
  14: WeaponType.SCOUT,
  9: WeaponType.HAND_CANNON,
  12: WeaponType.SNIPER,
  11: WeaponType.FUSION,
  17: WeaponType.SIDEARM,
  7: WeaponType.SHOTGUN,
  8: WeaponType.MACHINE_GUN,
  10: WeaponType.ROCKET_LAUNCHER,
  18: WeaponType.SWORD
};

/// The categories of weapons.
/// This enum is necessary as some weapons may be of a given type but end up
/// equipped in a different slot.
enum WeaponCategory { PRIMARY, SPECIAL, HEAVY }

/// Returns the weapon category listed in the category list, or null if it cannot
/// be found.
WeaponCategory getWeaponCategory(List<int> categories) {
  if (categories.contains(2)) {
    return WeaponCategory.PRIMARY;
  } else if (categories.contains(3)) {
    return WeaponCategory.SPECIAL;
  } else if (categories.contains(4)) {
    return WeaponCategory.HEAVY;
  } else {
    return null;
  }
}

/// Returns a short name for the given weapon.
String getWeaponTypeNickname(WeaponType type) {
  switch (type) {
    case WeaponType.AUTO:
      return 'Auto';
    case WeaponType.PULSE:
      return 'Pulse';
    case WeaponType.SCOUT:
      return 'Scout';
    case WeaponType.HAND_CANNON:
      return 'HC';
    case WeaponType.SNIPER:
      return 'Sniper';
    case WeaponType.FUSION:
      return 'Fusion';
    case WeaponType.SIDEARM:
      return 'Sidearm';
    case WeaponType.SHOTGUN:
      return 'Shotgun';
    case WeaponType.MACHINE_GUN:
      return 'MG';
    case WeaponType.ROCKET_LAUNCHER:
      return 'RL';
    case WeaponType.SWORD:
      return 'Sword';
    default:
      throw 'Unknown weapon type: $type';
  }
}

/// Represents a weapon.
class Weapon implements Comparable {
  final ItemId id;
  final String name;
  final WeaponType type;
  final WeaponCategory category;
  final Rarity rarity;

  const Weapon(this.id, this.name, this.type, this.category, this.rarity);

  bool get isPrimary => category == WeaponCategory.PRIMARY;

  bool get isSpecial => category == WeaponCategory.SPECIAL;

  bool get isHeavy => category == WeaponCategory.HEAVY;

  @override
  String toString() => '$name $type $rarity';

  @override
  int compareTo(Weapon other) {
    return type.index - other.type.index;
  }
}

/// The various types of armor pieces.
enum ArmorType { HELMET, GAUNTLETS, CHEST, BOOTS, CLASS_ITEM, ARTIFACT, GHOST }

/// Maps database identifiers to armor types.
ArmorType getArmorTypeFromCategories(List<int> categories) {
  if (categories.contains(45)) {
    return ArmorType.HELMET;
  } else if (categories.contains(46)) {
    return ArmorType.GAUNTLETS;
  } else if (categories.contains(47)) {
    return ArmorType.CHEST;
  } else if (categories.contains(48)) {
    return ArmorType.BOOTS;
  } else if (categories.contains(49)) {
    return ArmorType.CLASS_ITEM;
  } else {
    return null;
  }
}

/// Represents a piece of armor.
class Armor implements Comparable {
  final ItemId id;
  final String name;
  final Class clazz;
  final ArmorType type;
  final Rarity rarity;

  const Armor(this.id, this.name, this.clazz, this.type, this.rarity);

  @override
  String toString() => '$name $clazz $type $rarity';

  @override
  int compareTo(Armor other) {
    return type.index - other.type.index;
  }
}

/// The definition of a grimoire card.
class GrimoireCard {
  final ItemId id;
  final String title;
  final String content;

  const GrimoireCard(this.id, this.title, this.content);

  @override
  String toString() => title;
}

/// A reference to a character's activity.
class ActivityReference {
  /// The activity's identifier.
  final int id;

  /// The activity's real type, if non-zero.
  final int typeId;

  const ActivityReference(int id) : this.withOverride(id, 0);

  const ActivityReference.withOverride(this.id, this.typeId);

  @override
  String toString() => '$id($typeId)';
}

/// Represents an in-game activity.
class Activity {
  final ItemId id;
  final String type;
  final String name;

  const Activity(this.id, this.type, this.name);

  @override
  String toString() => name;
}

/// The collection of weekly activities and their characteristics.
class WeeklyProgram {
  final ActivityReference nightfall;
  final List<String> nightfallModifiers;
  final String kingsFallChallenge;
  final List<String> poeModifiers;
  final ActivityReference cruciblePlaylist;
  final List<String> heroicStrikeModifiers;

  const WeeklyProgram(
      this.nightfall,
      this.nightfallModifiers,
      this.kingsFallChallenge,
      this.poeModifiers,
      this.cruciblePlaylist,
      this.heroicStrikeModifiers);
}
