module Evergreen.V345.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V345.Discord
import Evergreen.V345.FileStatus
import Evergreen.V345.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V345.Discord.PartialUser
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V345.Discord.UserAuth
    , user : Evergreen.V345.Discord.User
    , connection : Evergreen.V345.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V345.Discord.User
    , linkedTo : Evergreen.V345.Id.Id Evergreen.V345.Id.UserId
    , icon : Maybe Evergreen.V345.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
