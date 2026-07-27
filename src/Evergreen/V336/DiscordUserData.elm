module Evergreen.V336.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V336.Discord
import Evergreen.V336.FileStatus
import Evergreen.V336.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V336.Discord.PartialUser
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V336.Discord.UserAuth
    , user : Evergreen.V336.Discord.User
    , connection : Evergreen.V336.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V336.Discord.User
    , linkedTo : Evergreen.V336.Id.Id Evergreen.V336.Id.UserId
    , icon : Maybe Evergreen.V336.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
