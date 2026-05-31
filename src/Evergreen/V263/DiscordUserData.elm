module Evergreen.V263.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V263.Discord
import Evergreen.V263.FileStatus
import Evergreen.V263.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V263.Discord.PartialUser
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V263.Discord.UserAuth
    , user : Evergreen.V263.Discord.User
    , connection : Evergreen.V263.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V263.Discord.User
    , linkedTo : Evergreen.V263.Id.Id Evergreen.V263.Id.UserId
    , icon : Maybe Evergreen.V263.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
