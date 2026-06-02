module Evergreen.V266.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V266.Discord
import Evergreen.V266.FileStatus
import Evergreen.V266.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V266.Discord.PartialUser
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V266.Discord.UserAuth
    , user : Evergreen.V266.Discord.User
    , connection : Evergreen.V266.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V266.Discord.User
    , linkedTo : Evergreen.V266.Id.Id Evergreen.V266.Id.UserId
    , icon : Maybe Evergreen.V266.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
