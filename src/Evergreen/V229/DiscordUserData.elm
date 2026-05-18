module Evergreen.V229.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V229.Discord
import Evergreen.V229.FileStatus
import Evergreen.V229.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V229.Discord.PartialUser
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V229.Discord.UserAuth
    , user : Evergreen.V229.Discord.User
    , connection : Evergreen.V229.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V229.Discord.User
    , linkedTo : Evergreen.V229.Id.Id Evergreen.V229.Id.UserId
    , icon : Maybe Evergreen.V229.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
