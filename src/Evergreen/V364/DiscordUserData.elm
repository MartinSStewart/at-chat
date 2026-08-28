module Evergreen.V364.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V364.Discord
import Evergreen.V364.FileStatus
import Evergreen.V364.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V364.Discord.PartialUser
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V364.Discord.UserAuth
    , user : Evergreen.V364.Discord.User
    , connection : Evergreen.V364.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V364.Discord.User
    , linkedTo : Evergreen.V364.Id.Id Evergreen.V364.Id.UserId
    , icon : Maybe Evergreen.V364.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
