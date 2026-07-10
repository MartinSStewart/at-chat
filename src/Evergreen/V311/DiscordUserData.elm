module Evergreen.V311.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V311.Discord
import Evergreen.V311.FileStatus
import Evergreen.V311.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V311.Discord.PartialUser
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V311.Discord.UserAuth
    , user : Evergreen.V311.Discord.User
    , connection : Evergreen.V311.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V311.Discord.User
    , linkedTo : Evergreen.V311.Id.Id Evergreen.V311.Id.UserId
    , icon : Maybe Evergreen.V311.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
