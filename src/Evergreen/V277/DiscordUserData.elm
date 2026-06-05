module Evergreen.V277.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V277.Discord
import Evergreen.V277.FileStatus
import Evergreen.V277.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V277.Discord.PartialUser
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V277.Discord.UserAuth
    , user : Evergreen.V277.Discord.User
    , connection : Evergreen.V277.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V277.Discord.User
    , linkedTo : Evergreen.V277.Id.Id Evergreen.V277.Id.UserId
    , icon : Maybe Evergreen.V277.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
