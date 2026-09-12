module Evergreen.V379.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V379.Discord
import Evergreen.V379.FileStatus
import Evergreen.V379.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V379.Discord.PartialUser
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V379.Discord.UserAuth
    , user : Evergreen.V379.Discord.User
    , connection : Evergreen.V379.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V379.Discord.User
    , linkedTo : Evergreen.V379.Id.Id Evergreen.V379.Id.UserId
    , icon : Maybe Evergreen.V379.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
