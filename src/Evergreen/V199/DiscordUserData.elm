module Evergreen.V199.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V199.Discord
import Evergreen.V199.FileStatus
import Evergreen.V199.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V199.Discord.PartialUser
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V199.Discord.UserAuth
    , user : Evergreen.V199.Discord.User
    , connection : Evergreen.V199.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V199.Discord.User
    , linkedTo : Evergreen.V199.Id.Id Evergreen.V199.Id.UserId
    , icon : Maybe Evergreen.V199.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
