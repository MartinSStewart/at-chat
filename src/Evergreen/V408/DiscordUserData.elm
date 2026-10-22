module Evergreen.V408.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V408.Discord
import Evergreen.V408.FileStatus
import Evergreen.V408.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V408.Discord.PartialUser
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V408.Discord.UserAuth
    , user : Evergreen.V408.Discord.User
    , connection : Evergreen.V408.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V408.Discord.User
    , linkedTo : Evergreen.V408.Id.Id Evergreen.V408.Id.UserId
    , icon : Maybe Evergreen.V408.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
