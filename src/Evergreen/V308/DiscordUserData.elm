module Evergreen.V308.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V308.Discord
import Evergreen.V308.FileStatus
import Evergreen.V308.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V308.Discord.PartialUser
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V308.Discord.UserAuth
    , user : Evergreen.V308.Discord.User
    , connection : Evergreen.V308.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V308.Discord.User
    , linkedTo : Evergreen.V308.Id.Id Evergreen.V308.Id.UserId
    , icon : Maybe Evergreen.V308.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
