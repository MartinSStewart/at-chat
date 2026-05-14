module Evergreen.V218.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V218.Discord
import Evergreen.V218.FileStatus
import Evergreen.V218.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V218.Discord.PartialUser
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V218.Discord.UserAuth
    , user : Evergreen.V218.Discord.User
    , connection : Evergreen.V218.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V218.Discord.User
    , linkedTo : Evergreen.V218.Id.Id Evergreen.V218.Id.UserId
    , icon : Maybe Evergreen.V218.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
