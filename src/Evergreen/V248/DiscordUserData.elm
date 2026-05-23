module Evergreen.V248.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V248.Discord
import Evergreen.V248.FileStatus
import Evergreen.V248.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V248.Discord.PartialUser
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V248.Discord.UserAuth
    , user : Evergreen.V248.Discord.User
    , connection : Evergreen.V248.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V248.Discord.User
    , linkedTo : Evergreen.V248.Id.Id Evergreen.V248.Id.UserId
    , icon : Maybe Evergreen.V248.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
