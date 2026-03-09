module Evergreen.V148.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V148.Discord
import Evergreen.V148.FileStatus
import Evergreen.V148.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V148.Discord.PartialUser
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V148.Discord.UserAuth
    , user : Evergreen.V148.Discord.User
    , connection : Evergreen.V148.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V148.Discord.User
    , linkedTo : Evergreen.V148.Id.Id Evergreen.V148.Id.UserId
    , icon : Maybe Evergreen.V148.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
