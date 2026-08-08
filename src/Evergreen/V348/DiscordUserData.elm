module Evergreen.V348.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V348.Discord
import Evergreen.V348.FileStatus
import Evergreen.V348.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V348.Discord.PartialUser
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V348.Discord.UserAuth
    , user : Evergreen.V348.Discord.User
    , connection : Evergreen.V348.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V348.Discord.User
    , linkedTo : Evergreen.V348.Id.Id Evergreen.V348.Id.UserId
    , icon : Maybe Evergreen.V348.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
