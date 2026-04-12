module Evergreen.V194.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V194.Discord
import Evergreen.V194.FileStatus
import Evergreen.V194.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V194.Discord.PartialUser
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V194.Discord.UserAuth
    , user : Evergreen.V194.Discord.User
    , connection : Evergreen.V194.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V194.Discord.User
    , linkedTo : Evergreen.V194.Id.Id Evergreen.V194.Id.UserId
    , icon : Maybe Evergreen.V194.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
