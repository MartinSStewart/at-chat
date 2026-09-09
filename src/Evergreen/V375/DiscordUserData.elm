module Evergreen.V375.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V375.Discord
import Evergreen.V375.FileStatus
import Evergreen.V375.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V375.Discord.PartialUser
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V375.Discord.UserAuth
    , user : Evergreen.V375.Discord.User
    , connection : Evergreen.V375.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V375.Discord.User
    , linkedTo : Evergreen.V375.Id.Id Evergreen.V375.Id.UserId
    , icon : Maybe Evergreen.V375.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
