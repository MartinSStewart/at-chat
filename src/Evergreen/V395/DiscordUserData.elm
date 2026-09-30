module Evergreen.V395.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V395.Discord
import Evergreen.V395.FileStatus
import Evergreen.V395.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V395.Discord.PartialUser
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V395.Discord.UserAuth
    , user : Evergreen.V395.Discord.User
    , connection : Evergreen.V395.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V395.Discord.User
    , linkedTo : Evergreen.V395.Id.Id Evergreen.V395.Id.UserId
    , icon : Maybe Evergreen.V395.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
