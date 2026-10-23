module Evergreen.V409.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V409.Discord
import Evergreen.V409.FileStatus
import Evergreen.V409.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V409.Discord.PartialUser
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V409.Discord.UserAuth
    , user : Evergreen.V409.Discord.User
    , connection : Evergreen.V409.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V409.Discord.User
    , linkedTo : Evergreen.V409.Id.Id Evergreen.V409.Id.UserId
    , icon : Maybe Evergreen.V409.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
