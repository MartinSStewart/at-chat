module Evergreen.V368.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V368.Discord
import Evergreen.V368.FileStatus
import Evergreen.V368.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V368.Discord.PartialUser
    , icon : Maybe Evergreen.V368.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V368.Discord.UserAuth
    , user : Evergreen.V368.Discord.User
    , connection : Evergreen.V368.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , icon : Maybe Evergreen.V368.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V368.Discord.User
    , linkedTo : Evergreen.V368.Id.Id Evergreen.V368.Id.UserId
    , icon : Maybe Evergreen.V368.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
