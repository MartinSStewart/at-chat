module Evergreen.V370.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V370.Discord
import Evergreen.V370.FileStatus
import Evergreen.V370.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V370.Discord.PartialUser
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V370.Discord.UserAuth
    , user : Evergreen.V370.Discord.User
    , connection : Evergreen.V370.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V370.Discord.User
    , linkedTo : Evergreen.V370.Id.Id Evergreen.V370.Id.UserId
    , icon : Maybe Evergreen.V370.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
