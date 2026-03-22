module Evergreen.V167.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V167.Discord
import Evergreen.V167.FileStatus
import Evergreen.V167.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V167.Discord.PartialUser
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V167.Discord.UserAuth
    , user : Evergreen.V167.Discord.User
    , connection : Evergreen.V167.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V167.Discord.User
    , linkedTo : Evergreen.V167.Id.Id Evergreen.V167.Id.UserId
    , icon : Maybe Evergreen.V167.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
