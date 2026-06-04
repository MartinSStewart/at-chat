module Evergreen.V273.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V273.Discord
import Evergreen.V273.FileStatus
import Evergreen.V273.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V273.Discord.PartialUser
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V273.Discord.UserAuth
    , user : Evergreen.V273.Discord.User
    , connection : Evergreen.V273.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V273.Discord.User
    , linkedTo : Evergreen.V273.Id.Id Evergreen.V273.Id.UserId
    , icon : Maybe Evergreen.V273.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
