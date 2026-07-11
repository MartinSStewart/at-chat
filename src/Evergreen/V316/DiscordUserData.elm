module Evergreen.V316.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V316.Discord
import Evergreen.V316.FileStatus
import Evergreen.V316.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V316.Discord.PartialUser
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V316.Discord.UserAuth
    , user : Evergreen.V316.Discord.User
    , connection : Evergreen.V316.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V316.Discord.User
    , linkedTo : Evergreen.V316.Id.Id Evergreen.V316.Id.UserId
    , icon : Maybe Evergreen.V316.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
