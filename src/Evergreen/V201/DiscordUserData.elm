module Evergreen.V201.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V201.Discord
import Evergreen.V201.FileStatus
import Evergreen.V201.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V201.Discord.PartialUser
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V201.Discord.UserAuth
    , user : Evergreen.V201.Discord.User
    , connection : Evergreen.V201.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V201.Discord.User
    , linkedTo : Evergreen.V201.Id.Id Evergreen.V201.Id.UserId
    , icon : Maybe Evergreen.V201.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
