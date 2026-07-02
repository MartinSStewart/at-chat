module Evergreen.V299.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V299.Discord
import Evergreen.V299.FileStatus
import Evergreen.V299.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V299.Discord.PartialUser
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V299.Discord.UserAuth
    , user : Evergreen.V299.Discord.User
    , connection : Evergreen.V299.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V299.Discord.User
    , linkedTo : Evergreen.V299.Id.Id Evergreen.V299.Id.UserId
    , icon : Maybe Evergreen.V299.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
