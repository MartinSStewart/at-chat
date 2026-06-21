module Evergreen.V293.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V293.Discord
import Evergreen.V293.FileStatus
import Evergreen.V293.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V293.Discord.PartialUser
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V293.Discord.UserAuth
    , user : Evergreen.V293.Discord.User
    , connection : Evergreen.V293.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V293.Discord.User
    , linkedTo : Evergreen.V293.Id.Id Evergreen.V293.Id.UserId
    , icon : Maybe Evergreen.V293.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
