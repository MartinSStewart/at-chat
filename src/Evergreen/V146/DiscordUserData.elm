module Evergreen.V146.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V146.Discord
import Evergreen.V146.FileStatus
import Evergreen.V146.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V146.Discord.PartialUser
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V146.Discord.UserAuth
    , user : Evergreen.V146.Discord.User
    , connection : Evergreen.V146.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V146.Discord.User
    , linkedTo : Evergreen.V146.Id.Id Evergreen.V146.Id.UserId
    , icon : Maybe Evergreen.V146.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
