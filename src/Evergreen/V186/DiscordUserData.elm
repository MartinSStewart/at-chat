module Evergreen.V186.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V186.Discord
import Evergreen.V186.FileStatus
import Evergreen.V186.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V186.Discord.PartialUser
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V186.Discord.UserAuth
    , user : Evergreen.V186.Discord.User
    , connection : Evergreen.V186.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V186.Discord.User
    , linkedTo : Evergreen.V186.Id.Id Evergreen.V186.Id.UserId
    , icon : Maybe Evergreen.V186.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
