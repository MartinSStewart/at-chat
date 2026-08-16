module Evergreen.V353.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V353.Discord
import Evergreen.V353.FileStatus
import Evergreen.V353.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V353.Discord.PartialUser
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V353.Discord.UserAuth
    , user : Evergreen.V353.Discord.User
    , connection : Evergreen.V353.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V353.Discord.User
    , linkedTo : Evergreen.V353.Id.Id Evergreen.V353.Id.UserId
    , icon : Maybe Evergreen.V353.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
