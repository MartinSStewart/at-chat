module Evergreen.V327.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V327.Discord
import Evergreen.V327.FileStatus
import Evergreen.V327.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V327.Discord.PartialUser
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V327.Discord.UserAuth
    , user : Evergreen.V327.Discord.User
    , connection : Evergreen.V327.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V327.Discord.User
    , linkedTo : Evergreen.V327.Id.Id Evergreen.V327.Id.UserId
    , icon : Maybe Evergreen.V327.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
