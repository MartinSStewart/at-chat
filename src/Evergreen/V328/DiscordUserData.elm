module Evergreen.V328.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V328.Discord
import Evergreen.V328.FileStatus
import Evergreen.V328.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V328.Discord.PartialUser
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V328.Discord.UserAuth
    , user : Evergreen.V328.Discord.User
    , connection : Evergreen.V328.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V328.Discord.User
    , linkedTo : Evergreen.V328.Id.Id Evergreen.V328.Id.UserId
    , icon : Maybe Evergreen.V328.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
