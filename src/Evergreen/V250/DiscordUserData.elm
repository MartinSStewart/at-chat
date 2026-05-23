module Evergreen.V250.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V250.Discord
import Evergreen.V250.FileStatus
import Evergreen.V250.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V250.Discord.PartialUser
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V250.Discord.UserAuth
    , user : Evergreen.V250.Discord.User
    , connection : Evergreen.V250.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V250.Discord.User
    , linkedTo : Evergreen.V250.Id.Id Evergreen.V250.Id.UserId
    , icon : Maybe Evergreen.V250.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
