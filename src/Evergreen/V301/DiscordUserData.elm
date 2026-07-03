module Evergreen.V301.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V301.Discord
import Evergreen.V301.FileStatus
import Evergreen.V301.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V301.Discord.PartialUser
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V301.Discord.UserAuth
    , user : Evergreen.V301.Discord.User
    , connection : Evergreen.V301.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V301.Discord.User
    , linkedTo : Evergreen.V301.Id.Id Evergreen.V301.Id.UserId
    , icon : Maybe Evergreen.V301.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
