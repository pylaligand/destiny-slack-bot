// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

const _FLAG_DIRECTORY = 'directory';
const _FLAG_API_KEY = 'api_key';
const _FLAG_BACKUP = 'backup';

const _DB_FILE = 'destiny_world_content.sqlite';
const _BACKUP_FILE = '$_DB_FILE.backup';

/// Returns the URL of the most recent world content file.
Future<String> _getContentFileUrl(String apiKey) async {
  const url = 'http://www.bungie.net/Platform/Destiny/Manifest';
  final body = await http.read(url, headers: {'X-API-Key': apiKey});
  final json = JSON.decode(body);
  final urlPath = json['Response']['mobileWorldContentPaths']['en'];
  return 'http://bungie.net$urlPath';
}

main(List<String> args) async {
  final parser = new ArgParser()
    ..addOption(_FLAG_DIRECTORY,
        help: 'Destination folder for the database file')
    ..addOption(_FLAG_API_KEY, help: 'Bungie API key')
    ..addFlag(_FLAG_BACKUP,
        help: 'Whether to back up an existing db file', defaultsTo: true);
  final params = parser.parse(args);
  if (!params.options.contains(_FLAG_DIRECTORY) ||
      !params.options.contains(_FLAG_API_KEY)) {
    print(parser.usage);
    exit(1);
  }

  final String directory = params[_FLAG_DIRECTORY];
  final String apiKey = params[_FLAG_API_KEY];
  final bool shouldCreateBackup = params[_FLAG_BACKUP];

  print('Reading manifest...');
  final contentUrl = await _getContentFileUrl(apiKey);
  print('Database found at $contentUrl');

  print('Downloading database...');
  final zippedBytes = (await http.get(contentUrl)).bodyBytes;
  print('Unzipping file...');
  final archive = new ZipDecoder().decodeBytes(zippedBytes);
  final dbContent = archive.first.content;
  print('Database has ${dbContent.length} bytes');

  final dbFile = new File(path.join(directory, _DB_FILE));
  if (dbFile.existsSync()) {
    if (dbContent.length == await dbFile.length()) {
      print('Database unchanged, nothing to do.');
      return;
    }
    if (shouldCreateBackup) {
      print('Creating backup...');
      final backupFile = new File(path.join(directory, _BACKUP_FILE));
      backupFile.writeAsBytesSync(dbFile.readAsBytesSync());
    } else {
      print('No backup requested');
    }
  } else {
    print('No existing database to back up');
  }
  dbFile.writeAsBytesSync(dbContent);
  print('Database updated at ${dbFile.path}!');
}
