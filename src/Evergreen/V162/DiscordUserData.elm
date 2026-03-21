module Evergreen.V162.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V162.Discord
import Evergreen.V162.FileStatus
import Evergreen.V162.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V162.Discord.PartialUser
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V162.Discord.UserAuth
    , user : Evergreen.V162.Discord.User
    , connection : Evergreen.V162.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V162.Discord.User
    , linkedTo : Evergreen.V162.Id.Id Evergreen.V162.Id.UserId
    , icon : Maybe Evergreen.V162.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
