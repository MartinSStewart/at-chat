module DiscordUserData exposing
    ( DiscordBasicUserData
    , DiscordFullUserData
    , DiscordUserData(..)
    , DiscordUserLoadingData(..)
    , NeedsAuthAgainData
    , icon
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


{-| `markEverythingAsViewedOnceLoaded` is set when the account is first linked. The
guilds, channels and DMs it brings along don't exist yet at that point, so the flag is
carried until the gateway hands us the data and everything can be marked as read. It
stays `False` when reloading an already linked account, since that would throw away
unread markers the user still cares about.
-}
type alias DiscordFullUserData =
    { auth : Discord.UserAuth
    , user : Discord.User
    , connection : Discord.Model Websocket.Connection
    , linkedTo : Id UserId
    , icon : Maybe FileHash
    , linkedAt : Time.Posix
    , isLoadingData : DiscordUserLoadingData
    , markEverythingAsViewedOnceLoaded : Bool
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


icon : DiscordUserData -> Maybe FileHash
icon discordUser =
    case discordUser of
        BasicData data ->
            data.icon

        FullData data ->
            data.icon

        NeedsAuthAgain data ->
            data.icon
