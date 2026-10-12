module Evergreen.V404.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V404.Discord
import Evergreen.V404.FileStatus
import Evergreen.V404.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V404.Discord.PartialUser
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V404.Discord.UserAuth
    , user : Evergreen.V404.Discord.User
    , connection : Evergreen.V404.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V404.Discord.User
    , linkedTo : Evergreen.V404.Id.Id Evergreen.V404.Id.UserId
    , icon : Maybe Evergreen.V404.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
