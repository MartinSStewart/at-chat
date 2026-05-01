module Evergreen.V213.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V213.Discord
import Evergreen.V213.FileStatus
import Evergreen.V213.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V213.Discord.PartialUser
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V213.Discord.UserAuth
    , user : Evergreen.V213.Discord.User
    , connection : Evergreen.V213.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V213.Discord.User
    , linkedTo : Evergreen.V213.Id.Id Evergreen.V213.Id.UserId
    , icon : Maybe Evergreen.V213.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
