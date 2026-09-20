module Evergreen.V384.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V384.Discord
import Evergreen.V384.FileStatus
import Evergreen.V384.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V384.Discord.PartialUser
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V384.Discord.UserAuth
    , user : Evergreen.V384.Discord.User
    , connection : Evergreen.V384.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V384.Discord.User
    , linkedTo : Evergreen.V384.Id.Id Evergreen.V384.Id.UserId
    , icon : Maybe Evergreen.V384.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
