module Evergreen.V419.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V419.Discord
import Evergreen.V419.FileStatus
import Evergreen.V419.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V419.Discord.PartialUser
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V419.Discord.UserAuth
    , user : Evergreen.V419.Discord.User
    , connection : Evergreen.V419.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V419.Discord.User
    , linkedTo : Evergreen.V419.Id.Id Evergreen.V419.Id.UserId
    , icon : Maybe Evergreen.V419.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
