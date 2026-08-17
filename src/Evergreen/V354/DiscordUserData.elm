module Evergreen.V354.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V354.Discord
import Evergreen.V354.FileStatus
import Evergreen.V354.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V354.Discord.PartialUser
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V354.Discord.UserAuth
    , user : Evergreen.V354.Discord.User
    , connection : Evergreen.V354.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V354.Discord.User
    , linkedTo : Evergreen.V354.Id.Id Evergreen.V354.Id.UserId
    , icon : Maybe Evergreen.V354.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
