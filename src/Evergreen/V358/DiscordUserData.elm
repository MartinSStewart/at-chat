module Evergreen.V358.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V358.Discord
import Evergreen.V358.FileStatus
import Evergreen.V358.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V358.Discord.PartialUser
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V358.Discord.UserAuth
    , user : Evergreen.V358.Discord.User
    , connection : Evergreen.V358.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V358.Discord.User
    , linkedTo : Evergreen.V358.Id.Id Evergreen.V358.Id.UserId
    , icon : Maybe Evergreen.V358.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
