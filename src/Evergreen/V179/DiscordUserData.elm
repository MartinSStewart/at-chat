module Evergreen.V179.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V179.Discord
import Evergreen.V179.FileStatus
import Evergreen.V179.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V179.Discord.PartialUser
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V179.Discord.UserAuth
    , user : Evergreen.V179.Discord.User
    , connection : Evergreen.V179.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V179.Discord.User
    , linkedTo : Evergreen.V179.Id.Id Evergreen.V179.Id.UserId
    , icon : Maybe Evergreen.V179.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
