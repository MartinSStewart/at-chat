module Evergreen.V176.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V176.Discord
import Evergreen.V176.FileStatus
import Evergreen.V176.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V176.Discord.PartialUser
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V176.Discord.UserAuth
    , user : Evergreen.V176.Discord.User
    , connection : Evergreen.V176.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V176.Discord.User
    , linkedTo : Evergreen.V176.Id.Id Evergreen.V176.Id.UserId
    , icon : Maybe Evergreen.V176.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
