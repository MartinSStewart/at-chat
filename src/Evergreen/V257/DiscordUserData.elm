module Evergreen.V257.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V257.Discord
import Evergreen.V257.FileStatus
import Evergreen.V257.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V257.Discord.PartialUser
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V257.Discord.UserAuth
    , user : Evergreen.V257.Discord.User
    , connection : Evergreen.V257.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V257.Discord.User
    , linkedTo : Evergreen.V257.Id.Id Evergreen.V257.Id.UserId
    , icon : Maybe Evergreen.V257.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
