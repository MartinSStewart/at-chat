module Evergreen.V251.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V251.Discord
import Evergreen.V251.FileStatus
import Evergreen.V251.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V251.Discord.PartialUser
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V251.Discord.UserAuth
    , user : Evergreen.V251.Discord.User
    , connection : Evergreen.V251.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V251.Discord.User
    , linkedTo : Evergreen.V251.Id.Id Evergreen.V251.Id.UserId
    , icon : Maybe Evergreen.V251.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
