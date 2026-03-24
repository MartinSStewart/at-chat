module Evergreen.V169.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V169.Discord
import Evergreen.V169.FileStatus
import Evergreen.V169.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V169.Discord.PartialUser
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V169.Discord.UserAuth
    , user : Evergreen.V169.Discord.User
    , connection : Evergreen.V169.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V169.Discord.User
    , linkedTo : Evergreen.V169.Id.Id Evergreen.V169.Id.UserId
    , icon : Maybe Evergreen.V169.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
