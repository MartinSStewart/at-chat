module Evergreen.V341.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V341.Discord
import Evergreen.V341.FileStatus
import Evergreen.V341.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V341.Discord.PartialUser
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V341.Discord.UserAuth
    , user : Evergreen.V341.Discord.User
    , connection : Evergreen.V341.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V341.Discord.User
    , linkedTo : Evergreen.V341.Id.Id Evergreen.V341.Id.UserId
    , icon : Maybe Evergreen.V341.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
