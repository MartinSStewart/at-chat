module Evergreen.V197.DiscordUserData exposing (..)

import Effect.Time
import Effect.Websocket
import Evergreen.V197.Discord
import Evergreen.V197.FileStatus
import Evergreen.V197.Id


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Effect.Time.Posix
    | DiscordUserLoadingFailed Effect.Time.Posix


type alias DiscordBasicUserData =
    { user : Evergreen.V197.Discord.PartialUser
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    }


type alias DiscordFullUserData =
    { auth : Evergreen.V197.Discord.UserAuth
    , user : Evergreen.V197.Discord.User
    , connection : Evergreen.V197.Discord.Model Effect.Websocket.Connection
    , linkedTo : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Evergreen.V197.Discord.User
    , linkedTo : Evergreen.V197.Id.Id Evergreen.V197.Id.UserId
    , icon : Maybe Evergreen.V197.FileStatus.FileHash
    , linkedAt : Effect.Time.Posix
    }


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData
