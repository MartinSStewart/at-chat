module Evergreen.V216.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V216.Discord
import Evergreen.V216.FileStatus
import Evergreen.V216.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V216.Discord.PartialUser
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V216.Discord.UserAuth
    , user : Evergreen.V216.Discord.User
    , connection : Evergreen.V216.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V216.Discord.User
    , linkedTo : Evergreen.V216.Id.Id Evergreen.V216.Id.UserId
    , icon : Maybe Evergreen.V216.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
