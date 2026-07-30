module Evergreen.V340.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V340.Discord
import Evergreen.V340.FileStatus
import Evergreen.V340.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V340.Discord.PartialUser
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V340.Discord.UserAuth
    , user : Evergreen.V340.Discord.User
    , connection : Evergreen.V340.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V340.Discord.User
    , linkedTo : Evergreen.V340.Id.Id Evergreen.V340.Id.UserId
    , icon : Maybe Evergreen.V340.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
