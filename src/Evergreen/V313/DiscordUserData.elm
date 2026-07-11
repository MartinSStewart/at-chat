module Evergreen.V313.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V313.Discord
import Evergreen.V313.FileStatus
import Evergreen.V313.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V313.Discord.PartialUser
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V313.Discord.UserAuth
    , user : Evergreen.V313.Discord.User
    , connection : Evergreen.V313.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V313.Discord.User
    , linkedTo : Evergreen.V313.Id.Id Evergreen.V313.Id.UserId
    , icon : Maybe Evergreen.V313.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
