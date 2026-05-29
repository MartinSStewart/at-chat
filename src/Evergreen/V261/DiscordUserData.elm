module Evergreen.V261.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V261.Discord
import Evergreen.V261.FileStatus
import Evergreen.V261.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V261.Discord.PartialUser
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V261.Discord.UserAuth
    , user : Evergreen.V261.Discord.User
    , connection : Evergreen.V261.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V261.Discord.User
    , linkedTo : Evergreen.V261.Id.Id Evergreen.V261.Id.UserId
    , icon : Maybe Evergreen.V261.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
