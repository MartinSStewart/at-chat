module Evergreen.V166.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V166.Discord
import Evergreen.V166.FileStatus
import Evergreen.V166.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V166.Discord.PartialUser
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V166.Discord.UserAuth
    , user : Evergreen.V166.Discord.User
    , connection : Evergreen.V166.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V166.Discord.User
    , linkedTo : Evergreen.V166.Id.Id Evergreen.V166.Id.UserId
    , icon : Maybe Evergreen.V166.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
