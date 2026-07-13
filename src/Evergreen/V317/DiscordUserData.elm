module Evergreen.V317.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V317.Discord
import Evergreen.V317.FileStatus
import Evergreen.V317.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V317.Discord.PartialUser
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V317.Discord.UserAuth
    , user : Evergreen.V317.Discord.User
    , connection : Evergreen.V317.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V317.Discord.User
    , linkedTo : Evergreen.V317.Id.Id Evergreen.V317.Id.UserId
    , icon : Maybe Evergreen.V317.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
