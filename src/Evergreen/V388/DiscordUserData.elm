module Evergreen.V388.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V388.Discord
import Evergreen.V388.FileStatus
import Evergreen.V388.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V388.Discord.PartialUser
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V388.Discord.UserAuth
    , user : Evergreen.V388.Discord.User
    , connection : Evergreen.V388.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V388.Discord.User
    , linkedTo : Evergreen.V388.Id.Id Evergreen.V388.Id.UserId
    , icon : Maybe Evergreen.V388.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
