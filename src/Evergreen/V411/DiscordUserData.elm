module Evergreen.V411.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V411.Discord
import Evergreen.V411.FileStatus
import Evergreen.V411.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V411.Discord.PartialUser
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V411.Discord.UserAuth
    , user : Evergreen.V411.Discord.User
    , connection : Evergreen.V411.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V411.Id.Id Evergreen.V411.Id.UserId
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V411.Discord.User
    , linkedTo : Evergreen.V411.Id.Id Evergreen.V411.Id.UserId
    , icon : Maybe Evergreen.V411.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
