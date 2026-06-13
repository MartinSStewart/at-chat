module Evergreen.V287.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V287.Discord
import Evergreen.V287.FileStatus
import Evergreen.V287.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V287.Discord.PartialUser
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V287.Discord.UserAuth
    , user : Evergreen.V287.Discord.User
    , connection : Evergreen.V287.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V287.Discord.User
    , linkedTo : Evergreen.V287.Id.Id Evergreen.V287.Id.UserId
    , icon : Maybe Evergreen.V287.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
