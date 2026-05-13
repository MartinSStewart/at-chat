module Evergreen.V215.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V215.Discord
import Evergreen.V215.FileStatus
import Evergreen.V215.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V215.Discord.PartialUser
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V215.Discord.UserAuth
    , user : Evergreen.V215.Discord.User
    , connection : Evergreen.V215.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V215.Discord.User
    , linkedTo : Evergreen.V215.Id.Id Evergreen.V215.Id.UserId
    , icon : Maybe Evergreen.V215.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
