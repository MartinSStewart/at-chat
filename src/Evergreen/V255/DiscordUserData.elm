module Evergreen.V255.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V255.Discord
import Evergreen.V255.FileStatus
import Evergreen.V255.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V255.Discord.PartialUser
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V255.Discord.UserAuth
    , user : Evergreen.V255.Discord.User
    , connection : Evergreen.V255.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V255.Discord.User
    , linkedTo : Evergreen.V255.Id.Id Evergreen.V255.Id.UserId
    , icon : Maybe Evergreen.V255.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
