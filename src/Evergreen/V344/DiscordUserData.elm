module Evergreen.V344.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V344.Discord
import Evergreen.V344.FileStatus
import Evergreen.V344.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V344.Discord.PartialUser
    , icon : Maybe Evergreen.V344.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V344.Discord.UserAuth
    , user : Evergreen.V344.Discord.User
    , connection : Evergreen.V344.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V344.Id.Id Evergreen.V344.Id.UserId
    , icon : Maybe Evergreen.V344.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V344.Discord.User
    , linkedTo : Evergreen.V344.Id.Id Evergreen.V344.Id.UserId
    , icon : Maybe Evergreen.V344.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
