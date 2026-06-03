module Evergreen.V270.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V270.Discord
import Evergreen.V270.FileStatus
import Evergreen.V270.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V270.Discord.PartialUser
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V270.Discord.UserAuth
    , user : Evergreen.V270.Discord.User
    , connection : Evergreen.V270.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V270.Discord.User
    , linkedTo : Evergreen.V270.Id.Id Evergreen.V270.Id.UserId
    , icon : Maybe Evergreen.V270.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
