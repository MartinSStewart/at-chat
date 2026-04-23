module Evergreen.V207.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V207.Discord
import Evergreen.V207.FileStatus
import Evergreen.V207.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V207.Discord.PartialUser
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V207.Discord.UserAuth
    , user : Evergreen.V207.Discord.User
    , connection : Evergreen.V207.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V207.Discord.User
    , linkedTo : Evergreen.V207.Id.Id Evergreen.V207.Id.UserId
    , icon : Maybe Evergreen.V207.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
