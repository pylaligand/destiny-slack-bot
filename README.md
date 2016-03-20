# Destiny bot for Slack

## Commands

- Trials of Osiris
  - /trials [gamertag]
  - look teams up for Trials of Osiris

## Configuration

Your team token must be added to the Heroku configuration, either via the web interface or via the command line:
```sh
heroku config:set SLACK_TEAM_TOKEN=abcde01234ghijk56789
```

## Running locally

```sh
SLACK_TEAM_TOKEN=abcde01234ghijk56789 pub run bin/server.dart
```
