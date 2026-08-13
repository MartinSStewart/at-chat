module Evergreen.V351.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V351.Discord
import Evergreen.V351.FileStatus
import Evergreen.V351.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V351.Discord.PartialUser
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V351.Discord.UserAuth
    , user : Evergreen.V351.Discord.User
    , connection : Evergreen.V351.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V351.Discord.User
    , linkedTo : Evergreen.V351.Id.Id Evergreen.V351.Id.UserId
    , icon : Maybe Evergreen.V351.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
