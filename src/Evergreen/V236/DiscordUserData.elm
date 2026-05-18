module Evergreen.V236.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V236.Discord
import Evergreen.V236.FileStatus
import Evergreen.V236.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V236.Discord.PartialUser
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V236.Discord.UserAuth
    , user : Evergreen.V236.Discord.User
    , connection : Evergreen.V236.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V236.Discord.User
    , linkedTo : Evergreen.V236.Id.Id Evergreen.V236.Id.UserId
    , icon : Maybe Evergreen.V236.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
