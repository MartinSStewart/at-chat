module Evergreen.V209.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V209.Discord
import Evergreen.V209.FileStatus
import Evergreen.V209.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V209.Discord.PartialUser
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V209.Discord.UserAuth
    , user : Evergreen.V209.Discord.User
    , connection : Evergreen.V209.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V209.Discord.User
    , linkedTo : Evergreen.V209.Id.Id Evergreen.V209.Id.UserId
    , icon : Maybe Evergreen.V209.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
