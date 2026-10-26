module Evergreen.V413.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V413.Discord
import Evergreen.V413.FileStatus
import Evergreen.V413.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V413.Discord.PartialUser
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V413.Discord.UserAuth
    , user : Evergreen.V413.Discord.User
    , connection : Evergreen.V413.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V413.Discord.User
    , linkedTo : Evergreen.V413.Id.Id Evergreen.V413.Id.UserId
    , icon : Maybe Evergreen.V413.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
