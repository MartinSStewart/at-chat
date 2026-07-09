module Evergreen.V309.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V309.Discord
import Evergreen.V309.FileStatus
import Evergreen.V309.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V309.Discord.PartialUser
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V309.Discord.UserAuth
    , user : Evergreen.V309.Discord.User
    , connection : Evergreen.V309.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V309.Discord.User
    , linkedTo : Evergreen.V309.Id.Id Evergreen.V309.Id.UserId
    , icon : Maybe Evergreen.V309.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
