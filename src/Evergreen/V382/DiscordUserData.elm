module Evergreen.V382.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V382.Discord
import Evergreen.V382.FileStatus
import Evergreen.V382.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V382.Discord.PartialUser
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V382.Discord.UserAuth
    , user : Evergreen.V382.Discord.User
    , connection : Evergreen.V382.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V382.Discord.User
    , linkedTo : Evergreen.V382.Id.Id Evergreen.V382.Id.UserId
    , icon : Maybe Evergreen.V382.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
