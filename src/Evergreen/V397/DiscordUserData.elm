module Evergreen.V397.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V397.Discord
import Evergreen.V397.FileStatus
import Evergreen.V397.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V397.Discord.PartialUser
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V397.Discord.UserAuth
    , user : Evergreen.V397.Discord.User
    , connection : Evergreen.V397.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V397.Discord.User
    , linkedTo : Evergreen.V397.Id.Id Evergreen.V397.Id.UserId
    , icon : Maybe Evergreen.V397.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
