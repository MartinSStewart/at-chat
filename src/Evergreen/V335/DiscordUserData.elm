module Evergreen.V335.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V335.Discord
import Evergreen.V335.FileStatus
import Evergreen.V335.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V335.Discord.PartialUser
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V335.Discord.UserAuth
    , user : Evergreen.V335.Discord.User
    , connection : Evergreen.V335.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V335.Discord.User
    , linkedTo : Evergreen.V335.Id.Id Evergreen.V335.Id.UserId
    , icon : Maybe Evergreen.V335.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
