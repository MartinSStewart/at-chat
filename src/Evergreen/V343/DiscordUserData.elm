module Evergreen.V343.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V343.Discord
import Evergreen.V343.FileStatus
import Evergreen.V343.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V343.Discord.PartialUser
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V343.Discord.UserAuth
    , user : Evergreen.V343.Discord.User
    , connection : Evergreen.V343.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V343.Discord.User
    , linkedTo : Evergreen.V343.Id.Id Evergreen.V343.Id.UserId
    , icon : Maybe Evergreen.V343.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
