# Destiny bot for Slack

[![Build status](https://travis-ci.org/pylaligand/destiny-slack-bot.svg?branch=master)](https://travis-ci.org/pylaligand/destiny-slack-bot)

## Commands

- Trials of Osiris
  - /trials [gamertag]
  - look teams up for Trials of Osiris
  - inspired by the [GuardianGG bot](https://github.com/slavikus/guardiangg-bot)
- Online clan members
  - /online [xbl|psn]
  - checks who's currently online playing Destiny

## Configuration

Several configuration values must be passed to Heroku. This can be done either via the web interface or via the command line:
```sh
heroku config:set PARAMETER_NAME=abcde01234ghijk56789
```

Here are the required parameters:
- *SLACK_VALIDATION_TOKENS*: the [validation tokens](https://api.slack.com/slash-commands#triggering_a_command)
for the Slack custom integrations
- *BUNGIE_API_KEY*: needed to talk to the Bungie API; register [here](https://www.bungie.net/en/User/API)
- *BUNGIE_CLAN_ID*: your clan ID, easily found when navigating to your clan
page on bungie.net, which has the form `https://www.bungie.net/en/Clan/Forum/{clan_id}`

## Running locally

```sh
PARAM1=foo123 PARAM2=bar456 pub run bin/server.dart
```
