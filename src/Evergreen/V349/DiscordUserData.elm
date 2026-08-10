module Evergreen.V349.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V349.Discord
import Evergreen.V349.FileStatus
import Evergreen.V349.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V349.Discord.PartialUser
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V349.Discord.UserAuth
    , user : Evergreen.V349.Discord.User
    , connection : Evergreen.V349.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V349.Discord.User
    , linkedTo : Evergreen.V349.Id.Id Evergreen.V349.Id.UserId
    , icon : Maybe Evergreen.V349.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
