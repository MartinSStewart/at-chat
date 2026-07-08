module Evergreen.V307.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V307.Discord
import Evergreen.V307.FileStatus
import Evergreen.V307.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V307.Discord.PartialUser
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V307.Discord.UserAuth
    , user : Evergreen.V307.Discord.User
    , connection : Evergreen.V307.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V307.Discord.User
    , linkedTo : Evergreen.V307.Id.Id Evergreen.V307.Id.UserId
    , icon : Maybe Evergreen.V307.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
