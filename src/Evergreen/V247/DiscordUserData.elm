module Evergreen.V247.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V247.Discord
import Evergreen.V247.FileStatus
import Evergreen.V247.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V247.Discord.PartialUser
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V247.Discord.UserAuth
    , user : Evergreen.V247.Discord.User
    , connection : Evergreen.V247.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V247.Discord.User
    , linkedTo : Evergreen.V247.Id.Id Evergreen.V247.Id.UserId
    , icon : Maybe Evergreen.V247.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
