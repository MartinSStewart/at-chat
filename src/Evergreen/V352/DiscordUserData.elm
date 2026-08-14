module Evergreen.V352.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V352.Discord
import Evergreen.V352.FileStatus
import Evergreen.V352.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V352.Discord.PartialUser
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V352.Discord.UserAuth
    , user : Evergreen.V352.Discord.User
    , connection : Evergreen.V352.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V352.Discord.User
    , linkedTo : Evergreen.V352.Id.Id Evergreen.V352.Id.UserId
    , icon : Maybe Evergreen.V352.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
