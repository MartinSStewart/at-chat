module Evergreen.V193.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V193.Discord
import Evergreen.V193.FileStatus
import Evergreen.V193.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V193.Discord.PartialUser
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V193.Discord.UserAuth
    , user : Evergreen.V193.Discord.User
    , connection : Evergreen.V193.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V193.Discord.User
    , linkedTo : Evergreen.V193.Id.Id Evergreen.V193.Id.UserId
    , icon : Maybe Evergreen.V193.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
