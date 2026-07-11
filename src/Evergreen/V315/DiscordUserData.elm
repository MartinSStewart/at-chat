module Evergreen.V315.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V315.Discord
import Evergreen.V315.FileStatus
import Evergreen.V315.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V315.Discord.PartialUser
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V315.Discord.UserAuth
    , user : Evergreen.V315.Discord.User
    , connection : Evergreen.V315.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V315.Discord.User
    , linkedTo : Evergreen.V315.Id.Id Evergreen.V315.Id.UserId
    , icon : Maybe Evergreen.V315.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
