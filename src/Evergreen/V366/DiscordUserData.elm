module Evergreen.V366.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V366.Discord
import Evergreen.V366.FileStatus
import Evergreen.V366.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V366.Discord.PartialUser
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V366.Discord.UserAuth
    , user : Evergreen.V366.Discord.User
    , connection : Evergreen.V366.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V366.Discord.User
    , linkedTo : Evergreen.V366.Id.Id Evergreen.V366.Id.UserId
    , icon : Maybe Evergreen.V366.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
