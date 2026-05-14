module Evergreen.V217.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V217.Discord
import Evergreen.V217.FileStatus
import Evergreen.V217.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V217.Discord.PartialUser
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V217.Discord.UserAuth
    , user : Evergreen.V217.Discord.User
    , connection : Evergreen.V217.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V217.Discord.User
    , linkedTo : Evergreen.V217.Id.Id Evergreen.V217.Id.UserId
    , icon : Maybe Evergreen.V217.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
