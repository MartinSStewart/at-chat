module Evergreen.V267.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V267.Discord
import Evergreen.V267.FileStatus
import Evergreen.V267.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V267.Discord.PartialUser
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V267.Discord.UserAuth
    , user : Evergreen.V267.Discord.User
    , connection : Evergreen.V267.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V267.Discord.User
    , linkedTo : Evergreen.V267.Id.Id Evergreen.V267.Id.UserId
    , icon : Maybe Evergreen.V267.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
