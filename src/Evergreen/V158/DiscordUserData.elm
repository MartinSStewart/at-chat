module Evergreen.V158.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V158.Discord
import Evergreen.V158.FileStatus
import Evergreen.V158.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V158.Discord.PartialUser
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V158.Discord.UserAuth
    , user : Evergreen.V158.Discord.User
    , connection : Evergreen.V158.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V158.Discord.User
    , linkedTo : Evergreen.V158.Id.Id Evergreen.V158.Id.UserId
    , icon : Maybe Evergreen.V158.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
