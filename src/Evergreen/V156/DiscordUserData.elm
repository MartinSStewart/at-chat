module Evergreen.V156.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V156.Discord
import Evergreen.V156.FileStatus
import Evergreen.V156.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V156.Discord.PartialUser
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V156.Discord.UserAuth
    , user : Evergreen.V156.Discord.User
    , connection : Evergreen.V156.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V156.Discord.User
    , linkedTo : Evergreen.V156.Id.Id Evergreen.V156.Id.UserId
    , icon : Maybe Evergreen.V156.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
