module Evergreen.V381.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V381.Discord
import Evergreen.V381.FileStatus
import Evergreen.V381.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V381.Discord.PartialUser
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V381.Discord.UserAuth
    , user : Evergreen.V381.Discord.User
    , connection : Evergreen.V381.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V381.Discord.User
    , linkedTo : Evergreen.V381.Id.Id Evergreen.V381.Id.UserId
    , icon : Maybe Evergreen.V381.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
