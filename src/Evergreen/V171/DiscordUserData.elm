module Evergreen.V171.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V171.Discord
import Evergreen.V171.FileStatus
import Evergreen.V171.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V171.Discord.PartialUser
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V171.Discord.UserAuth
    , user : Evergreen.V171.Discord.User
    , connection : Evergreen.V171.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V171.Discord.User
    , linkedTo : Evergreen.V171.Id.Id Evergreen.V171.Id.UserId
    , icon : Maybe Evergreen.V171.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
