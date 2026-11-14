module Evergreen.V422.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V422.Discord
import Evergreen.V422.FileStatus
import Evergreen.V422.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V422.Discord.PartialUser
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V422.Discord.UserAuth
    , user : Evergreen.V422.Discord.User
    , connection : Evergreen.V422.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V422.Discord.User
    , linkedTo : Evergreen.V422.Id.Id Evergreen.V422.Id.UserId
    , icon : Maybe Evergreen.V422.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
