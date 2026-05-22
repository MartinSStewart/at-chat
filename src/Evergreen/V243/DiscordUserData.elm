module Evergreen.V243.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V243.Discord
import Evergreen.V243.FileStatus
import Evergreen.V243.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V243.Discord.PartialUser
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V243.Discord.UserAuth
    , user : Evergreen.V243.Discord.User
    , connection : Evergreen.V243.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V243.Discord.User
    , linkedTo : Evergreen.V243.Id.Id Evergreen.V243.Id.UserId
    , icon : Maybe Evergreen.V243.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
