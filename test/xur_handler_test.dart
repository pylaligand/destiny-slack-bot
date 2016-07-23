// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:bungie_client/bungie_types.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../lib/context_params.dart' as param;
import '../lib/xur_handler.dart';

import 'utils.dart';

const _ITEM_ID = const ItemId(314);
const _ITEM = const XurExoticItem(_ITEM_ID, true);
const _ARMOR = const Armor(
    _ITEM_ID, 'Shiny', Class.HUNTER, ArmorType.CHEST, Rarity.EXOTIC);

void main() {
  MockBungieDatabase database;
  MockBungieClient bungieClient;
  Map<String, dynamic> context;
  XurHandler handler;

  setUp(() {
    database = new MockBungieDatabase();
    bungieClient = new MockBungieClient();
    context = {
      param.BUNGIE_CLIENT: bungieClient,
      param.BUNGIE_DATABASE: database,
    };
    handler = new XurHandler();
  });

  tearDown(() {
    database = null;
    bungieClient = null;
    context = null;
    handler = null;
  });

  test('lists items', () async {
    when(bungieClient.getXurInventory()).thenReturn(const [_ITEM]);
    when(database.getArmorPiece(_ITEM_ID)).thenReturn(new Future.value(_ARMOR));
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains(_ARMOR.name));
  });

  test('handles absence', () async {
    when(bungieClient.getXurInventory()).thenReturn(const <XurExoticItem>[]);
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains('not available'));
  });
}
