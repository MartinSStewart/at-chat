module Evergreen.V185.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V185.Discord
import Evergreen.V185.FileStatus
import Evergreen.V185.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V185.Discord.PartialUser
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V185.Discord.UserAuth
    , user : Evergreen.V185.Discord.User
    , connection : Evergreen.V185.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V185.Discord.User
    , linkedTo : Evergreen.V185.Id.Id Evergreen.V185.Id.UserId
    , icon : Maybe Evergreen.V185.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
