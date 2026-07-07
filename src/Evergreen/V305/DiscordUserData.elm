module Evergreen.V305.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V305.Discord
import Evergreen.V305.FileStatus
import Evergreen.V305.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V305.Discord.PartialUser
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V305.Discord.UserAuth
    , user : Evergreen.V305.Discord.User
    , connection : Evergreen.V305.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V305.Discord.User
    , linkedTo : Evergreen.V305.Id.Id Evergreen.V305.Id.UserId
    , icon : Maybe Evergreen.V305.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
