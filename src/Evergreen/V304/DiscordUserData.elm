module Evergreen.V304.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V304.Discord
import Evergreen.V304.FileStatus
import Evergreen.V304.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V304.Discord.PartialUser
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V304.Discord.UserAuth
    , user : Evergreen.V304.Discord.User
    , connection : Evergreen.V304.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V304.Discord.User
    , linkedTo : Evergreen.V304.Id.Id Evergreen.V304.Id.UserId
    , icon : Maybe Evergreen.V304.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
