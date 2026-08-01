module Evergreen.V342.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V342.Discord
import Evergreen.V342.FileStatus
import Evergreen.V342.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V342.Discord.PartialUser
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V342.Discord.UserAuth
    , user : Evergreen.V342.Discord.User
    , connection : Evergreen.V342.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V342.Discord.User
    , linkedTo : Evergreen.V342.Id.Id Evergreen.V342.Id.UserId
    , icon : Maybe Evergreen.V342.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
