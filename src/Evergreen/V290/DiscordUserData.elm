module Evergreen.V290.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V290.Discord
import Evergreen.V290.FileStatus
import Evergreen.V290.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V290.Discord.PartialUser
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V290.Discord.UserAuth
    , user : Evergreen.V290.Discord.User
    , connection : Evergreen.V290.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V290.Discord.User
    , linkedTo : Evergreen.V290.Id.Id Evergreen.V290.Id.UserId
    , icon : Maybe Evergreen.V290.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
