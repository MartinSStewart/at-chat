module Evergreen.V254.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V254.Discord
import Evergreen.V254.FileStatus
import Evergreen.V254.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V254.Discord.PartialUser
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V254.Discord.UserAuth
    , user : Evergreen.V254.Discord.User
    , connection : Evergreen.V254.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V254.Discord.User
    , linkedTo : Evergreen.V254.Id.Id Evergreen.V254.Id.UserId
    , icon : Maybe Evergreen.V254.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
