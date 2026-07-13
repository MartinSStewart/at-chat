module Evergreen.V318.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V318.Discord
import Evergreen.V318.FileStatus
import Evergreen.V318.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V318.Discord.PartialUser
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V318.Discord.UserAuth
    , user : Evergreen.V318.Discord.User
    , connection : Evergreen.V318.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V318.Discord.User
    , linkedTo : Evergreen.V318.Id.Id Evergreen.V318.Id.UserId
    , icon : Maybe Evergreen.V318.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
