module Evergreen.V182.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V182.Discord
import Evergreen.V182.FileStatus
import Evergreen.V182.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V182.Discord.PartialUser
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V182.Discord.UserAuth
    , user : Evergreen.V182.Discord.User
    , connection : Evergreen.V182.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V182.Discord.User
    , linkedTo : Evergreen.V182.Id.Id Evergreen.V182.Id.UserId
    , icon : Maybe Evergreen.V182.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
