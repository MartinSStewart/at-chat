module Evergreen.V367.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V367.Discord
import Evergreen.V367.FileStatus
import Evergreen.V367.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V367.Discord.PartialUser
    , icon : Maybe Evergreen.V367.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V367.Discord.UserAuth
    , user : Evergreen.V367.Discord.User
    , connection : Evergreen.V367.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V367.Id.Id Evergreen.V367.Id.UserId
    , icon : Maybe Evergreen.V367.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V367.Discord.User
    , linkedTo : Evergreen.V367.Id.Id Evergreen.V367.Id.UserId
    , icon : Maybe Evergreen.V367.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
