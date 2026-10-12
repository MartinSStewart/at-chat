module Evergreen.V405.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V405.Discord
import Evergreen.V405.FileStatus
import Evergreen.V405.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V405.Discord.PartialUser
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V405.Discord.UserAuth
    , user : Evergreen.V405.Discord.User
    , connection : Evergreen.V405.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V405.Discord.User
    , linkedTo : Evergreen.V405.Id.Id Evergreen.V405.Id.UserId
    , icon : Maybe Evergreen.V405.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
