module Evergreen.V360.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V360.Discord
import Evergreen.V360.FileStatus
import Evergreen.V360.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V360.Discord.PartialUser
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V360.Discord.UserAuth
    , user : Evergreen.V360.Discord.User
    , connection : Evergreen.V360.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V360.Discord.User
    , linkedTo : Evergreen.V360.Id.Id Evergreen.V360.Id.UserId
    , icon : Maybe Evergreen.V360.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
