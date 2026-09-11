module Evergreen.V377.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V377.Discord
import Evergreen.V377.FileStatus
import Evergreen.V377.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V377.Discord.PartialUser
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V377.Discord.UserAuth
    , user : Evergreen.V377.Discord.User
    , connection : Evergreen.V377.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V377.Discord.User
    , linkedTo : Evergreen.V377.Id.Id Evergreen.V377.Id.UserId
    , icon : Maybe Evergreen.V377.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
