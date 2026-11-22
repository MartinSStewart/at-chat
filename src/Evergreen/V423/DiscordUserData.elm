module Evergreen.V423.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V423.Discord
import Evergreen.V423.FileStatus
import Evergreen.V423.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V423.Discord.PartialUser
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V423.Discord.UserAuth
    , user : Evergreen.V423.Discord.User
    , connection : Evergreen.V423.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V423.Discord.User
    , linkedTo : Evergreen.V423.Id.Id Evergreen.V423.Id.UserId
    , icon : Maybe Evergreen.V423.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
