module Evergreen.V203.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V203.Discord
import Evergreen.V203.FileStatus
import Evergreen.V203.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V203.Discord.PartialUser
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V203.Discord.UserAuth
    , user : Evergreen.V203.Discord.User
    , connection : Evergreen.V203.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V203.Discord.User
    , linkedTo : Evergreen.V203.Id.Id Evergreen.V203.Id.UserId
    , icon : Maybe Evergreen.V203.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
