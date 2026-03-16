module Evergreen.V154.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V154.Discord
import Evergreen.V154.FileStatus
import Evergreen.V154.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V154.Discord.PartialUser
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V154.Discord.UserAuth
    , user : Evergreen.V154.Discord.User
    , connection : Evergreen.V154.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V154.Discord.User
    , linkedTo : Evergreen.V154.Id.Id Evergreen.V154.Id.UserId
    , icon : Maybe Evergreen.V154.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
