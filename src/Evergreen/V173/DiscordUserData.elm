module Evergreen.V173.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V173.Discord
import Evergreen.V173.FileStatus
import Evergreen.V173.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V173.Discord.PartialUser
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V173.Discord.UserAuth
    , user : Evergreen.V173.Discord.User
    , connection : Evergreen.V173.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V173.Discord.User
    , linkedTo : Evergreen.V173.Id.Id Evergreen.V173.Id.UserId
    , icon : Maybe Evergreen.V173.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
