module Evergreen.V421.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V421.Discord
import Evergreen.V421.FileStatus
import Evergreen.V421.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V421.Discord.PartialUser
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V421.Discord.UserAuth
    , user : Evergreen.V421.Discord.User
    , connection : Evergreen.V421.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V421.Discord.User
    , linkedTo : Evergreen.V421.Id.Id Evergreen.V421.Id.UserId
    , icon : Maybe Evergreen.V421.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
