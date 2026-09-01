module Evergreen.V365.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V365.Discord
import Evergreen.V365.FileStatus
import Evergreen.V365.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V365.Discord.PartialUser
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V365.Discord.UserAuth
    , user : Evergreen.V365.Discord.User
    , connection : Evergreen.V365.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V365.Discord.User
    , linkedTo : Evergreen.V365.Id.Id Evergreen.V365.Id.UserId
    , icon : Maybe Evergreen.V365.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
