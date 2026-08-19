module Evergreen.V359.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V359.Discord
import Evergreen.V359.FileStatus
import Evergreen.V359.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V359.Discord.PartialUser
    , icon : Maybe Evergreen.V359.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V359.Discord.UserAuth
    , user : Evergreen.V359.Discord.User
    , connection : Evergreen.V359.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V359.Id.Id Evergreen.V359.Id.UserId
    , icon : Maybe Evergreen.V359.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V359.Discord.User
    , linkedTo : Evergreen.V359.Id.Id Evergreen.V359.Id.UserId
    , icon : Maybe Evergreen.V359.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
