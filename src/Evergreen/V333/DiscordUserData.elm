module Evergreen.V333.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V333.Discord
import Evergreen.V333.FileStatus
import Evergreen.V333.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V333.Discord.PartialUser
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V333.Discord.UserAuth
    , user : Evergreen.V333.Discord.User
    , connection : Evergreen.V333.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V333.Discord.User
    , linkedTo : Evergreen.V333.Id.Id Evergreen.V333.Id.UserId
    , icon : Maybe Evergreen.V333.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
