module Evergreen.V163.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V163.Discord
import Evergreen.V163.FileStatus
import Evergreen.V163.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V163.Discord.PartialUser
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V163.Discord.UserAuth
    , user : Evergreen.V163.Discord.User
    , connection : Evergreen.V163.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V163.Discord.User
    , linkedTo : Evergreen.V163.Id.Id Evergreen.V163.Id.UserId
    , icon : Maybe Evergreen.V163.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
