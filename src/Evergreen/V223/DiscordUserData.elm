module Evergreen.V223.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V223.Discord
import Evergreen.V223.FileStatus
import Evergreen.V223.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V223.Discord.PartialUser
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V223.Discord.UserAuth
    , user : Evergreen.V223.Discord.User
    , connection : Evergreen.V223.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V223.Discord.User
    , linkedTo : Evergreen.V223.Id.Id Evergreen.V223.Id.UserId
    , icon : Maybe Evergreen.V223.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
