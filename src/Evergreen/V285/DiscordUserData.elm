module Evergreen.V285.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V285.Discord
import Evergreen.V285.FileStatus
import Evergreen.V285.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V285.Discord.PartialUser
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V285.Discord.UserAuth
    , user : Evergreen.V285.Discord.User
    , connection : Evergreen.V285.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V285.Discord.User
    , linkedTo : Evergreen.V285.Id.Id Evergreen.V285.Id.UserId
    , icon : Maybe Evergreen.V285.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
