module Evergreen.V183.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V183.Discord
import Evergreen.V183.FileStatus
import Evergreen.V183.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V183.Discord.PartialUser
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V183.Discord.UserAuth
    , user : Evergreen.V183.Discord.User
    , connection : Evergreen.V183.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V183.Discord.User
    , linkedTo : Evergreen.V183.Id.Id Evergreen.V183.Id.UserId
    , icon : Maybe Evergreen.V183.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
