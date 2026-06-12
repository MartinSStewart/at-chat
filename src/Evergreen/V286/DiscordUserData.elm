module Evergreen.V286.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V286.Discord
import Evergreen.V286.FileStatus
import Evergreen.V286.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V286.Discord.PartialUser
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V286.Discord.UserAuth
    , user : Evergreen.V286.Discord.User
    , connection : Evergreen.V286.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V286.Discord.User
    , linkedTo : Evergreen.V286.Id.Id Evergreen.V286.Id.UserId
    , icon : Maybe Evergreen.V286.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
