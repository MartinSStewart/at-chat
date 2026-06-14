module Evergreen.V289.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V289.Discord
import Evergreen.V289.FileStatus
import Evergreen.V289.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V289.Discord.PartialUser
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V289.Discord.UserAuth
    , user : Evergreen.V289.Discord.User
    , connection : Evergreen.V289.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V289.Discord.User
    , linkedTo : Evergreen.V289.Id.Id Evergreen.V289.Id.UserId
    , icon : Maybe Evergreen.V289.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
