module Evergreen.V228.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V228.Discord
import Evergreen.V228.FileStatus
import Evergreen.V228.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V228.Discord.PartialUser
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V228.Discord.UserAuth
    , user : Evergreen.V228.Discord.User
    , connection : Evergreen.V228.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V228.Discord.User
    , linkedTo : Evergreen.V228.Id.Id Evergreen.V228.Id.UserId
    , icon : Maybe Evergreen.V228.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
