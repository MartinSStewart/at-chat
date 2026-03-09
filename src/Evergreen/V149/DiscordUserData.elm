module Evergreen.V149.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V149.Discord
import Evergreen.V149.FileStatus
import Evergreen.V149.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V149.Discord.PartialUser
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V149.Discord.UserAuth
    , user : Evergreen.V149.Discord.User
    , connection : Evergreen.V149.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V149.Discord.User
    , linkedTo : Evergreen.V149.Id.Id Evergreen.V149.Id.UserId
    , icon : Maybe Evergreen.V149.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
