module Evergreen.V403.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V403.Discord
import Evergreen.V403.FileStatus
import Evergreen.V403.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V403.Discord.PartialUser
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V403.Discord.UserAuth
    , user : Evergreen.V403.Discord.User
    , connection : Evergreen.V403.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V403.Discord.User
    , linkedTo : Evergreen.V403.Id.Id Evergreen.V403.Id.UserId
    , icon : Maybe Evergreen.V403.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
