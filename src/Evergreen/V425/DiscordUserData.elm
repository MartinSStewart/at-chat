module Evergreen.V425.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V425.Discord
import Evergreen.V425.FileStatus
import Evergreen.V425.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V425.Discord.PartialUser
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V425.Discord.UserAuth
    , user : Evergreen.V425.Discord.User
    , connection : Evergreen.V425.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V425.Discord.User
    , linkedTo : Evergreen.V425.Id.Id Evergreen.V425.Id.UserId
    , icon : Maybe Evergreen.V425.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
