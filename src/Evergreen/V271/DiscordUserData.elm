module Evergreen.V271.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V271.Discord
import Evergreen.V271.FileStatus
import Evergreen.V271.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V271.Discord.PartialUser
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V271.Discord.UserAuth
    , user : Evergreen.V271.Discord.User
    , connection : Evergreen.V271.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V271.Discord.User
    , linkedTo : Evergreen.V271.Id.Id Evergreen.V271.Id.UserId
    , icon : Maybe Evergreen.V271.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
