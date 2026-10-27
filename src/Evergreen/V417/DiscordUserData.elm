module Evergreen.V417.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V417.Discord
import Evergreen.V417.FileStatus
import Evergreen.V417.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V417.Discord.PartialUser
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V417.Discord.UserAuth
    , user : Evergreen.V417.Discord.User
    , connection : Evergreen.V417.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V417.Discord.User
    , linkedTo : Evergreen.V417.Id.Id Evergreen.V417.Id.UserId
    , icon : Maybe Evergreen.V417.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
