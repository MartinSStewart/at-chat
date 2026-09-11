module Evergreen.V378.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V378.Discord
import Evergreen.V378.FileStatus
import Evergreen.V378.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V378.Discord.PartialUser
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V378.Discord.UserAuth
    , user : Evergreen.V378.Discord.User
    , connection : Evergreen.V378.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V378.Discord.User
    , linkedTo : Evergreen.V378.Id.Id Evergreen.V378.Id.UserId
    , icon : Maybe Evergreen.V378.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
