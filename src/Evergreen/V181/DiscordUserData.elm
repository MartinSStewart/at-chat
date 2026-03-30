module Evergreen.V181.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V181.Discord
import Evergreen.V181.FileStatus
import Evergreen.V181.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V181.Discord.PartialUser
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V181.Discord.UserAuth
    , user : Evergreen.V181.Discord.User
    , connection : Evergreen.V181.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V181.Discord.User
    , linkedTo : Evergreen.V181.Id.Id Evergreen.V181.Id.UserId
    , icon : Maybe Evergreen.V181.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
