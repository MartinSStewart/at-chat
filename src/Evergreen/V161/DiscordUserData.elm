module Evergreen.V161.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V161.Discord
import Evergreen.V161.FileStatus
import Evergreen.V161.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V161.Discord.PartialUser
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V161.Discord.UserAuth
    , user : Evergreen.V161.Discord.User
    , connection : Evergreen.V161.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V161.Discord.User
    , linkedTo : Evergreen.V161.Id.Id Evergreen.V161.Id.UserId
    , icon : Maybe Evergreen.V161.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
