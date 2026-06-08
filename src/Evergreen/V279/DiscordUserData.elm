module Evergreen.V279.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V279.Discord
import Evergreen.V279.FileStatus
import Evergreen.V279.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V279.Discord.PartialUser
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V279.Discord.UserAuth
    , user : Evergreen.V279.Discord.User
    , connection : Evergreen.V279.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V279.Discord.User
    , linkedTo : Evergreen.V279.Id.Id Evergreen.V279.Id.UserId
    , icon : Maybe Evergreen.V279.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
