module Evergreen.V238.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V238.Discord
import Evergreen.V238.FileStatus
import Evergreen.V238.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V238.Discord.PartialUser
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V238.Discord.UserAuth
    , user : Evergreen.V238.Discord.User
    , connection : Evergreen.V238.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V238.Discord.User
    , linkedTo : Evergreen.V238.Id.Id Evergreen.V238.Id.UserId
    , icon : Maybe Evergreen.V238.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
