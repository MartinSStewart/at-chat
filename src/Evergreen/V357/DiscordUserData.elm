module Evergreen.V357.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V357.Discord
import Evergreen.V357.FileStatus
import Evergreen.V357.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V357.Discord.PartialUser
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V357.Discord.UserAuth
    , user : Evergreen.V357.Discord.User
    , connection : Evergreen.V357.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V357.Discord.User
    , linkedTo : Evergreen.V357.Id.Id Evergreen.V357.Id.UserId
    , icon : Maybe Evergreen.V357.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
