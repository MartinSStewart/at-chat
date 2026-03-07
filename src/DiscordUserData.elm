module DiscordUserData exposing
    ( DiscordBasicUserData
    , DiscordFullUserData
    , DiscordUserData(..)
    , DiscordUserLoadingData(..)
    , NeedsAuthAgainData
    , username
    )

import Discord
import Effect.Time as Time
import Effect.Websocket as Websocket
import FileStatus exposing (FileHash)
import Id exposing (Id, UserId)


type DiscordUserData
    = BasicData DiscordBasicUserData
    | FullData DiscordFullUserData
    | NeedsAuthAgain NeedsAuthAgainData


type alias DiscordFullUserData =
    { auth : Discord.UserAuth
    , user : Discord.User
    , connection : Discord.Model Websocket.Connection
    , linkedTo : Id UserId
    , icon : Maybe FileHash
    , linkedAt : Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


type alias NeedsAuthAgainData =
    { user : Discord.User
    , linkedTo : Id UserId
    , icon : Maybe FileHash
    , linkedAt : Time.Posix
    }


type alias DiscordBasicUserData =
    { user : Discord.PartialUser, icon : Maybe FileHash }


type DiscordUserLoadingData
    = DiscordUserLoadedSuccessfully
    | DiscordUserLoadingData Time.Posix
    | DiscordUserLoadingFailed Time.Posix


username : DiscordUserData -> String
username discordUser =
    case discordUser of
        BasicData data ->
            data.user.username

        FullData data ->
            data.user.username

        NeedsAuthAgain data ->
            data.user.username
