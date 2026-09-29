module Evergreen.V394.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V394.Discord
import Evergreen.V394.FileStatus
import Evergreen.V394.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V394.Discord.PartialUser
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V394.Discord.UserAuth
    , user : Evergreen.V394.Discord.User
    , connection : Evergreen.V394.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V394.Discord.User
    , linkedTo : Evergreen.V394.Id.Id Evergreen.V394.Id.UserId
    , icon : Maybe Evergreen.V394.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
