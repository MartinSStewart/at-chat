module Evergreen.V264.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V264.Discord
import Evergreen.V264.FileStatus
import Evergreen.V264.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V264.Discord.PartialUser
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V264.Discord.UserAuth
    , user : Evergreen.V264.Discord.User
    , connection : Evergreen.V264.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V264.Discord.User
    , linkedTo : Evergreen.V264.Id.Id Evergreen.V264.Id.UserId
    , icon : Maybe Evergreen.V264.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
