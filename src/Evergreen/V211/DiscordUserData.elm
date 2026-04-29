module Evergreen.V211.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V211.Discord
import Evergreen.V211.FileStatus
import Evergreen.V211.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V211.Discord.PartialUser
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V211.Discord.UserAuth
    , user : Evergreen.V211.Discord.User
    , connection : Evergreen.V211.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V211.Discord.User
    , linkedTo : Evergreen.V211.Id.Id Evergreen.V211.Id.UserId
    , icon : Maybe Evergreen.V211.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
