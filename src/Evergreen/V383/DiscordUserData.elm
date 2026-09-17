module Evergreen.V383.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V383.Discord
import Evergreen.V383.FileStatus
import Evergreen.V383.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V383.Discord.PartialUser
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V383.Discord.UserAuth
    , user : Evergreen.V383.Discord.User
    , connection : Evergreen.V383.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V383.Discord.User
    , linkedTo : Evergreen.V383.Id.Id Evergreen.V383.Id.UserId
    , icon : Maybe Evergreen.V383.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
