module Evergreen.V297.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V297.Discord
import Evergreen.V297.FileStatus
import Evergreen.V297.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V297.Discord.PartialUser
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V297.Discord.UserAuth
    , user : Evergreen.V297.Discord.User
    , connection : Evergreen.V297.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V297.Discord.User
    , linkedTo : Evergreen.V297.Id.Id Evergreen.V297.Id.UserId
    , icon : Maybe Evergreen.V297.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
