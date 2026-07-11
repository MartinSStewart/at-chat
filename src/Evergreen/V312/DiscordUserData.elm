module Evergreen.V312.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V312.Discord
import Evergreen.V312.FileStatus
import Evergreen.V312.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V312.Discord.PartialUser
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V312.Discord.UserAuth
    , user : Evergreen.V312.Discord.User
    , connection : Evergreen.V312.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V312.Discord.User
    , linkedTo : Evergreen.V312.Id.Id Evergreen.V312.Id.UserId
    , icon : Maybe Evergreen.V312.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
