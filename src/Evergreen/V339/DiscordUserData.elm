module Evergreen.V339.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V339.Discord
import Evergreen.V339.FileStatus
import Evergreen.V339.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V339.Discord.PartialUser
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V339.Discord.UserAuth
    , user : Evergreen.V339.Discord.User
    , connection : Evergreen.V339.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V339.Discord.User
    , linkedTo : Evergreen.V339.Id.Id Evergreen.V339.Id.UserId
    , icon : Maybe Evergreen.V339.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
