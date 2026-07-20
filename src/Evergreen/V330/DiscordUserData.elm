module Evergreen.V330.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V330.Discord
import Evergreen.V330.FileStatus
import Evergreen.V330.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V330.Discord.PartialUser
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V330.Discord.UserAuth
    , user : Evergreen.V330.Discord.User
    , connection : Evergreen.V330.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V330.Discord.User
    , linkedTo : Evergreen.V330.Id.Id Evergreen.V330.Id.UserId
    , icon : Maybe Evergreen.V330.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
