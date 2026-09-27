module Evergreen.V386.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V386.Discord
import Evergreen.V386.FileStatus
import Evergreen.V386.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V386.Discord.PartialUser
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V386.Discord.UserAuth
    , user : Evergreen.V386.Discord.User
    , connection : Evergreen.V386.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V386.Discord.User
    , linkedTo : Evergreen.V386.Id.Id Evergreen.V386.Id.UserId
    , icon : Maybe Evergreen.V386.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
