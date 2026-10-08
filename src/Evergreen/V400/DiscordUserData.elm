module Evergreen.V400.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V400.Discord
import Evergreen.V400.FileStatus
import Evergreen.V400.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V400.Discord.PartialUser
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V400.Discord.UserAuth
    , user : Evergreen.V400.Discord.User
    , connection : Evergreen.V400.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V400.Discord.User
    , linkedTo : Evergreen.V400.Id.Id Evergreen.V400.Id.UserId
    , icon : Maybe Evergreen.V400.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
