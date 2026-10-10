module Evergreen.V402.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V402.Discord
import Evergreen.V402.FileStatus
import Evergreen.V402.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V402.Discord.PartialUser
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V402.Discord.UserAuth
    , user : Evergreen.V402.Discord.User
    , connection : Evergreen.V402.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V402.Discord.User
    , linkedTo : Evergreen.V402.Id.Id Evergreen.V402.Id.UserId
    , icon : Maybe Evergreen.V402.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
