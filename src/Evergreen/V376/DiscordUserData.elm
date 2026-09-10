module Evergreen.V376.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V376.Discord
import Evergreen.V376.FileStatus
import Evergreen.V376.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V376.Discord.PartialUser
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V376.Discord.UserAuth
    , user : Evergreen.V376.Discord.User
    , connection : Evergreen.V376.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V376.Discord.User
    , linkedTo : Evergreen.V376.Id.Id Evergreen.V376.Id.UserId
    , icon : Maybe Evergreen.V376.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
