module Evergreen.V177.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V177.Discord
import Evergreen.V177.FileStatus
import Evergreen.V177.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V177.Discord.PartialUser
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V177.Discord.UserAuth
    , user : Evergreen.V177.Discord.User
    , connection : Evergreen.V177.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V177.Discord.User
    , linkedTo : Evergreen.V177.Id.Id Evergreen.V177.Id.UserId
    , icon : Maybe Evergreen.V177.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
