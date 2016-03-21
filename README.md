# Destiny bot for Slack

## Commands

- Trials of Osiris
  - /trials [gamertag]
  - look teams up for Trials of Osiris
  - inspired by the [GuardianGG bot](https://github.com/slavikus/guardiangg-bot)

## Configuration

Your team token must be added to the Heroku configuration, either via the web interface or via the command line:
```sh
heroku config:set SLACK_TEAM_TOKEN=abcde01234ghijk56789
```

Same thing with your Bungie API key:
```sh
heroku config:set BUNGIE_API_KEY=abcde01234ghijk56789
```

## Running locally

```sh
SLACK_TEAM_TOKEN=foo123 BUNGIE_API_KEY=bar456 pub run bin/server.dart
```
