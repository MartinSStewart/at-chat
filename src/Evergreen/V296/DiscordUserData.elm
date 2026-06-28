module Evergreen.V296.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V296.Discord
import Evergreen.V296.FileStatus
import Evergreen.V296.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V296.Discord.PartialUser
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V296.Discord.UserAuth
    , user : Evergreen.V296.Discord.User
    , connection : Evergreen.V296.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V296.Discord.User
    , linkedTo : Evergreen.V296.Id.Id Evergreen.V296.Id.UserId
    , icon : Maybe Evergreen.V296.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
