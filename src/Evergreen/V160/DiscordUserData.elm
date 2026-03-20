module Evergreen.V160.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V160.Discord
import Evergreen.V160.FileStatus
import Evergreen.V160.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V160.Discord.PartialUser
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V160.Discord.UserAuth
    , user : Evergreen.V160.Discord.User
    , connection : Evergreen.V160.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V160.Discord.User
    , linkedTo : Evergreen.V160.Id.Id Evergreen.V160.Id.UserId
    , icon : Maybe Evergreen.V160.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
