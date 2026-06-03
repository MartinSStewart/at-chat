module Evergreen.V269.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V269.Discord
import Evergreen.V269.FileStatus
import Evergreen.V269.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V269.Discord.PartialUser
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V269.Discord.UserAuth
    , user : Evergreen.V269.Discord.User
    , connection : Evergreen.V269.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V269.Discord.User
    , linkedTo : Evergreen.V269.Id.Id Evergreen.V269.Id.UserId
    , icon : Maybe Evergreen.V269.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
