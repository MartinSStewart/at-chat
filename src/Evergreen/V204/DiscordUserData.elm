module Evergreen.V204.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V204.Discord
import Evergreen.V204.FileStatus
import Evergreen.V204.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V204.Discord.PartialUser
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V204.Discord.UserAuth
    , user : Evergreen.V204.Discord.User
    , connection : Evergreen.V204.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V204.Discord.User
    , linkedTo : Evergreen.V204.Id.Id Evergreen.V204.Id.UserId
    , icon : Maybe Evergreen.V204.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
