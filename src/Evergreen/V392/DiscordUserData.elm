module Evergreen.V392.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V392.Discord
import Evergreen.V392.FileStatus
import Evergreen.V392.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V392.Discord.PartialUser
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V392.Discord.UserAuth
    , user : Evergreen.V392.Discord.User
    , connection : Evergreen.V392.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V392.Discord.User
    , linkedTo : Evergreen.V392.Id.Id Evergreen.V392.Id.UserId
    , icon : Maybe Evergreen.V392.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
