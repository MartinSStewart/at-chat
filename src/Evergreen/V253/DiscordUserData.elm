module Evergreen.V253.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V253.Discord
import Evergreen.V253.FileStatus
import Evergreen.V253.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V253.Discord.PartialUser
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V253.Discord.UserAuth
    , user : Evergreen.V253.Discord.User
    , connection : Evergreen.V253.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V253.Discord.User
    , linkedTo : Evergreen.V253.Id.Id Evergreen.V253.Id.UserId
    , icon : Maybe Evergreen.V253.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
