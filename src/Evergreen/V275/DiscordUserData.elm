module Evergreen.V275.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V275.Discord
import Evergreen.V275.FileStatus
import Evergreen.V275.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V275.Discord.PartialUser
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V275.Discord.UserAuth
    , user : Evergreen.V275.Discord.User
    , connection : Evergreen.V275.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V275.Discord.User
    , linkedTo : Evergreen.V275.Id.Id Evergreen.V275.Id.UserId
    , icon : Maybe Evergreen.V275.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
