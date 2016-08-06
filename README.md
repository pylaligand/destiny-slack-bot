# Destiny bot for Slack

[![Build status](https://travis-ci.org/pylaligand/destiny-slack-bot.svg?branch=master)](https://travis-ci.org/pylaligand/destiny-slack-bot)

This is a [Slack](http://www.slack.com) bot for
[Destiny](https://www.destinythegame.com/) clans. It exposes
commands to look up various aspects of the game thanks to
[the great API](https://www.bungie.net/en/Clan/Forum/39966) Bungie
published.

This bot runs on [Heroku](http://www.heroku.com) infrastructure, powered by
the [Dart build pack](https://github.com/igrigorik/heroku-buildpack-dart)
which publishes some tools and instructions to deploy a Dart app to Heroku.

Note that in Slack each command needs to be added as a
[custom integration](https://api.slack.com/custom-integrations). It should
be possible to package them as an app, although this has not be attempted
yet.

## Commands

- Trials of Osiris
  - `/trials [gamertag]`
  - look teams up for Trials of Osiris
  - inspired by the [GuardianGG bot](https://github.com/slavikus/guardiangg-bot)
- Online clan members
  - `/online [xbl | psn]`
  - check who is currently online playing Destiny
- Grimoire score
  - `/grimoire [gamertag | @username | nothing]`
  - view a player's grimoire score
- Grimoire cards
  - `/card`
  - show a random grimoire card
- Xur inventory
  - `/xur`
  - list Xur's inventory when he's around
- Twitch streams
  - `/twitch`
  - view active Twitch streams
- Weekly activities
  - `/weekly`
  - view activities for the week (nightfall strike, CoE modifiers, etc...)
- Moments of Triumph
  - `/triumphs`
  - check progress on Moments of Triumph
- LFG
  - `/lfg`
  - list games on [the100.io](https://www.the100.io)
- Time "wasted" on Destiny
  - `/wasted`
  - view time spent playing Destiny according to [wastedondestiny.com](https://www.wastedondestiny.com)

## Notifications

- Twitch
  - when a stream goes live
- LFG
  - when a game is created
  - when a game is about to start

## Configuration

Several configuration parameters must be passed to your Heroku dyno.
This can be done either via the web interface or via the command line:
```sh
heroku config:set PARAMETER_NAME=abcde01234ghijk56789
```

Here are the required parameters:
- `SLACK_VALIDATION_TOKENS`: the [validation tokens](https://api.slack.com/slash-commands#triggering_a_command)
for the Slack custom integrations
- `BUNGIE_API_KEY`: needed to query the Bungie API; register [here](https://www.bungie.net/en/User/API)
- `BUNGIE_CLAN_ID`: your clan ID, easily found when navigating to your clan
page on bungie.net, which has the form
`https://www.bungie.net/en/Clan/Forum/{clan_id}`
- `DATABASE_URL`: URI of the PostgreSQL database holding Destiny world data -
see next section
- `USE_DELAYED_RESPONSES`: whether to use a [delayed response](https://api.slack.com/slash-commands#responding_to_a_command)
when a query takes too long
- `TWITCH_STREAMERS`: comma-separated list of Twitch streamers to monitor
- `SLACK_BOT_TOKEN`: auth token for the [bot user](https://my.slack.com/services/new/bot); note that this token will also be used for slash commands
- `SLACK_BOT_CHANNEL`: name of the channel where notifications will be posted (note: the bot needs to be [manually invited](https://github.com/slackhq/node-slack-sdk/issues/26)
to the channel first)
- `THE_HUNDRED_AUTH_TOKEN`: the100 [group API key](https://mlapeter.gitbooks.io/the-100-api/content/)
- `THE_HUNDRED_GROUP_ID`: your the100 group id, found at `https://www.the100.io/groups/{group_id}`

## Database

The world database is created from the SQLite world database provided in the
[manifest](http://www.bungie.net/platform/Destiny/Manifest/) and downloaded via
`tool/download_world_content`. It is converted to a Postgres database with
`tool/create_database`.

A local Postgres instance will be needed for testing, whereas a live instance
can be set up on [Heroku](https://www.heroku.com/postgres). The local instance
is provisioned via the creation tool, while the live instance is bootstrapped
from the local instance with:
```
heroku pg:reset DATABASE_URL
heroku pg:push <local db name> DATABASE_URL --app <your app's name>
```

## Running locally

When running a local server, pass the configuration parameters as
environment variables:

```sh
PARAM1=foo123 PARAM2=bar456 pub run bin/server.dart
```

Note that you will likely want to set `USE_DELAYED_RESPONSES` to `false` when
testing locally so that you can receive command results with whichever tool you
use (e.g. http client GUI) to send the requests.
