// Copyright (c) 2016 P.Y. Laligand

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../lib/bungie_client.dart';
import '../lib/context_params.dart' as param;
import '../lib/online_handler.dart';

import 'utils.dart';

const _CLAN_ID = '123456789';
const _ON_XBOX = true;
const _ID_ONE = const DestinyId(_ON_XBOX, 'abcdef');
const _ID_TWO = const DestinyId(_ON_XBOX, 'ghijkl');
const _MEMBER_ONE = const ClanMember(_ID_ONE, 'member_one', _ON_XBOX);
const _MEMBER_TWO = const ClanMember(_ID_TWO, 'member_two', _ON_XBOX);
const _ACTIVITY = const ActivityReference(314);

void main() {
  MockBungieClient client;
  MockBungieDatabase database;
  Map<String, dynamic> context;
  OnlineHandler handler;

  setUp(() {
    client = new MockBungieClient();
    database = new MockBungieDatabase();
    context = {
      param.BUNGIE_CLIENT: client,
      param.BUNGIE_DATABASE: database,
      param.SLACK_TEXT: 'xbl'
    };
    handler = new OnlineHandler(_CLAN_ID);
  });

  tearDown(() {
    client = null;
    context = null;
    handler = null;
  });

  test('no member in clan', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX)).thenReturn(<ClanMember>[]);
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'], isNotNull);
  });

  test('invalid platform', () async {
    context[param.SLACK_TEXT] = 'bogus!';
    final json = await getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
    expect(json['text'], isNotNull);
    verifyZeroInteractions(client);
  });

  test('with online members', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX))
        .thenReturn(<ClanMember>[_MEMBER_ONE, _MEMBER_TWO]);
    when(client.getCurrentActivity(_MEMBER_ONE.id)).thenReturn(_ACTIVITY);
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains(_MEMBER_ONE.gamertag));
    expect(json['text'], isNot(contains(_MEMBER_TWO.gamertag)));
  });

  test('no online member', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX))
        .thenReturn(<ClanMember>[_MEMBER_ONE, _MEMBER_TWO]);
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'], isNotNull);
  });

  test('no character data', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX))
        .thenReturn(<ClanMember>[_MEMBER_ONE, _MEMBER_TWO]);
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'], isNotNull);
  });
}
