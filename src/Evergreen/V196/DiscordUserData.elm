module Evergreen.V196.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V196.Discord
import Evergreen.V196.FileStatus
import Evergreen.V196.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V196.Discord.PartialUser
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V196.Discord.UserAuth
    , user : Evergreen.V196.Discord.User
    , connection : Evergreen.V196.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V196.Discord.User
    , linkedTo : Evergreen.V196.Id.Id Evergreen.V196.Id.UserId
    , icon : Maybe Evergreen.V196.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
