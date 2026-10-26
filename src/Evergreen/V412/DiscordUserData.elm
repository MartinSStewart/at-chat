module Evergreen.V412.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V412.Discord
import Evergreen.V412.FileStatus
import Evergreen.V412.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V412.Discord.PartialUser
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V412.Discord.UserAuth
    , user : Evergreen.V412.Discord.User
    , connection : Evergreen.V412.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V412.Discord.User
    , linkedTo : Evergreen.V412.Id.Id Evergreen.V412.Id.UserId
    , icon : Maybe Evergreen.V412.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
