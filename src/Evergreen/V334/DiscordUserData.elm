module Evergreen.V334.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V334.Discord
import Evergreen.V334.FileStatus
import Evergreen.V334.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V334.Discord.PartialUser
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V334.Discord.UserAuth
    , user : Evergreen.V334.Discord.User
    , connection : Evergreen.V334.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V334.Discord.User
    , linkedTo : Evergreen.V334.Id.Id Evergreen.V334.Id.UserId
    , icon : Maybe Evergreen.V334.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
