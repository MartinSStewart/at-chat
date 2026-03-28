module Evergreen.V175.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V175.Discord
import Evergreen.V175.FileStatus
import Evergreen.V175.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V175.Discord.PartialUser
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V175.Discord.UserAuth
    , user : Evergreen.V175.Discord.User
    , connection : Evergreen.V175.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V175.Discord.User
    , linkedTo : Evergreen.V175.Id.Id Evergreen.V175.Id.UserId
    , icon : Maybe Evergreen.V175.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
