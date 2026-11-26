module Evergreen.V426.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V426.Discord
import Evergreen.V426.FileStatus
import Evergreen.V426.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V426.Discord.PartialUser
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V426.Discord.UserAuth
    , user : Evergreen.V426.Discord.User
    , connection : Evergreen.V426.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V426.Discord.User
    , linkedTo : Evergreen.V426.Id.Id Evergreen.V426.Id.UserId
    , icon : Maybe Evergreen.V426.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
