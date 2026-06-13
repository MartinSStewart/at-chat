module Evergreen.V288.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V288.Discord
import Evergreen.V288.FileStatus
import Evergreen.V288.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V288.Discord.PartialUser
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V288.Discord.UserAuth
    , user : Evergreen.V288.Discord.User
    , connection : Evergreen.V288.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V288.Discord.User
    , linkedTo : Evergreen.V288.Id.Id Evergreen.V288.Id.UserId
    , icon : Maybe Evergreen.V288.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
