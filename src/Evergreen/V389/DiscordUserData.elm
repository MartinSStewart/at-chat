module Evergreen.V389.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V389.Discord
import Evergreen.V389.FileStatus
import Evergreen.V389.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V389.Discord.PartialUser
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V389.Discord.UserAuth
    , user : Evergreen.V389.Discord.User
    , connection : Evergreen.V389.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V389.Discord.User
    , linkedTo : Evergreen.V389.Id.Id Evergreen.V389.Id.UserId
    , icon : Maybe Evergreen.V389.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
