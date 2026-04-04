module Evergreen.V190.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V190.Discord
import Evergreen.V190.FileStatus
import Evergreen.V190.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V190.Discord.PartialUser
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V190.Discord.UserAuth
    , user : Evergreen.V190.Discord.User
    , connection : Evergreen.V190.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V190.Discord.User
    , linkedTo : Evergreen.V190.Id.Id Evergreen.V190.Id.UserId
    , icon : Maybe Evergreen.V190.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
