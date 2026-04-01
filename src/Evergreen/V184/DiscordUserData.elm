module Evergreen.V184.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V184.Discord
import Evergreen.V184.FileStatus
import Evergreen.V184.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V184.Discord.PartialUser
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V184.Discord.UserAuth
    , user : Evergreen.V184.Discord.User
    , connection : Evergreen.V184.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V184.Discord.User
    , linkedTo : Evergreen.V184.Id.Id Evergreen.V184.Id.UserId
    , icon : Maybe Evergreen.V184.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
