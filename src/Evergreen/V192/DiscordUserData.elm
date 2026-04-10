module Evergreen.V192.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V192.Discord
import Evergreen.V192.FileStatus
import Evergreen.V192.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V192.Discord.PartialUser
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V192.Discord.UserAuth
    , user : Evergreen.V192.Discord.User
    , connection : Evergreen.V192.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V192.Discord.User
    , linkedTo : Evergreen.V192.Id.Id Evergreen.V192.Id.UserId
    , icon : Maybe Evergreen.V192.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
