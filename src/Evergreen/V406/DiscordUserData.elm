module Evergreen.V406.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V406.Discord
import Evergreen.V406.FileStatus
import Evergreen.V406.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V406.Discord.PartialUser
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V406.Discord.UserAuth
    , user : Evergreen.V406.Discord.User
    , connection : Evergreen.V406.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V406.Discord.User
    , linkedTo : Evergreen.V406.Id.Id Evergreen.V406.Id.UserId
    , icon : Maybe Evergreen.V406.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
