module Evergreen.V294.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V294.Discord
import Evergreen.V294.FileStatus
import Evergreen.V294.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V294.Discord.PartialUser
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V294.Discord.UserAuth
    , user : Evergreen.V294.Discord.User
    , connection : Evergreen.V294.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V294.Discord.User
    , linkedTo : Evergreen.V294.Id.Id Evergreen.V294.Id.UserId
    , icon : Maybe Evergreen.V294.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
