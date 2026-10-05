module Evergreen.V398.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V398.Discord
import Evergreen.V398.FileStatus
import Evergreen.V398.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V398.Discord.PartialUser
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V398.Discord.UserAuth
    , user : Evergreen.V398.Discord.User
    , connection : Evergreen.V398.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V398.Discord.User
    , linkedTo : Evergreen.V398.Id.Id Evergreen.V398.Id.UserId
    , icon : Maybe Evergreen.V398.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
