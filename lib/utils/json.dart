// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Requests JSON data from the given URL.
/// Returns null if the request failed.
Future<dynamic> get(String url, Logger log,
    {Map<String, String> headers}) async {
  final body = await http.read(url, headers: headers).catchError((e, _) {
    log.warning('Failed request: $e');
    return null;
  });
  if (body == null) {
    log.warning('Empty response');
    return null;
  }
  try {
    return JSON.decode(body);
  } on FormatException catch (e) {
    log.warning('Failed to decode content: $e');
    return null;
  }
}
