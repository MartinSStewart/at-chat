module Evergreen.V346.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V346.Discord
import Evergreen.V346.FileStatus
import Evergreen.V346.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V346.Discord.PartialUser
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V346.Discord.UserAuth
    , user : Evergreen.V346.Discord.User
    , connection : Evergreen.V346.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V346.Discord.User
    , linkedTo : Evergreen.V346.Id.Id Evergreen.V346.Id.UserId
    , icon : Maybe Evergreen.V346.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
