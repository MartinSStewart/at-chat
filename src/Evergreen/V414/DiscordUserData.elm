module Evergreen.V414.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V414.Discord
import Evergreen.V414.FileStatus
import Evergreen.V414.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V414.Discord.PartialUser
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V414.Discord.UserAuth
    , user : Evergreen.V414.Discord.User
    , connection : Evergreen.V414.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V414.Discord.User
    , linkedTo : Evergreen.V414.Id.Id Evergreen.V414.Id.UserId
    , icon : Maybe Evergreen.V414.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
