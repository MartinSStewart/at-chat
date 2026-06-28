module Evergreen.V295.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V295.Discord
import Evergreen.V295.FileStatus
import Evergreen.V295.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V295.Discord.PartialUser
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V295.Discord.UserAuth
    , user : Evergreen.V295.Discord.User
    , connection : Evergreen.V295.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V295.Discord.User
    , linkedTo : Evergreen.V295.Id.Id Evergreen.V295.Id.UserId
    , icon : Maybe Evergreen.V295.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
