module Evergreen.V210.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V210.Discord
import Evergreen.V210.FileStatus
import Evergreen.V210.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V210.Discord.PartialUser
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V210.Discord.UserAuth
    , user : Evergreen.V210.Discord.User
    , connection : Evergreen.V210.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V210.Discord.User
    , linkedTo : Evergreen.V210.Id.Id Evergreen.V210.Id.UserId
    , icon : Maybe Evergreen.V210.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
