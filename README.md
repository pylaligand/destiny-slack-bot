# Destiny bot for Slack

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
- *SLACK_TEAM_TOKEN*: the Slack team's [validation token](https://api.slack.com/slash-commands#triggering_a_command)
- *BUNGIE_API_KEY*: needed to talk to the Bungie API; register [here](https://www.bungie.net/en/User/API)
- *BUNGIE_CLAN_ID*: your clan ID, easily found when navigating to your clan
page on bungie.net, which has the form `https://www.bungie.net/en/Clan/Forum/{clan_id}`

## Running locally

```sh
PARAM1=foo123 PARAM2=bar456 pub run bin/server.dart
```
