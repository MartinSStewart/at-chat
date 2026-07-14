module Evergreen.V323.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V323.Discord
import Evergreen.V323.FileStatus
import Evergreen.V323.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V323.Discord.PartialUser
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V323.Discord.UserAuth
    , user : Evergreen.V323.Discord.User
    , connection : Evergreen.V323.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V323.Discord.User
    , linkedTo : Evergreen.V323.Id.Id Evergreen.V323.Id.UserId
    , icon : Maybe Evergreen.V323.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
