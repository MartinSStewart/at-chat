module Evergreen.V302.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V302.Discord
import Evergreen.V302.FileStatus
import Evergreen.V302.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V302.Discord.PartialUser
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V302.Discord.UserAuth
    , user : Evergreen.V302.Discord.User
    , connection : Evergreen.V302.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V302.Discord.User
    , linkedTo : Evergreen.V302.Id.Id Evergreen.V302.Id.UserId
    , icon : Maybe Evergreen.V302.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
