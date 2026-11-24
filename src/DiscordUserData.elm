module DiscordUserData exposing
    ( DiscordBasicUserData
    , DiscordFullUserData
    , DiscordUserData(..)
    , DiscordUserLoadingData(..)
    , NeedsAuthAgainData
    , icon
    , nameIn
    , names
    , username
    )

import Discord
import Effect.Time as Time
import Effect.Websocket as Websocket
import FileStatus exposing (FileHash)
import Id exposing (Id, UserId)
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)


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


{-| What a Discord user goes by in a guild: the nickname they set for themselves there, or
their username if they didn't.
-}
nameIn : SeqDict (Discord.Id Discord.UserId) PersonName -> DiscordUserData -> String
nameIn nicknames discordUser =
    let
        userId : Discord.Id Discord.UserId
        userId =
            case discordUser of
                BasicData data ->
                    data.user.id

                FullData data ->
                    data.user.id

                NeedsAuthAgain data ->
                    data.user.id
    in
    case SeqDict.get userId nicknames of
        Just nickname ->
            PersonName.toString nickname

        Nothing ->
            username discordUser


icon : DiscordUserData -> Maybe FileHash
icon discordUser =
    case discordUser of
        BasicData data ->
            data.icon

        FullData data ->
            data.icon

        NeedsAuthAgain data ->
            data.icon


{-| The names of some Discord users, for writing out messages that mention them.
-}
names : List (Discord.Id Discord.UserId) -> SeqDict (Discord.Id Discord.UserId) DiscordUserData -> SeqDict (Discord.Id Discord.UserId) { name : PersonName }
names userIds users =
    List.foldl
        (\userId dict ->
            case SeqDict.get userId users of
                Just user ->
                    SeqDict.insert userId { name = username user |> PersonName.fromStringLossy } dict

                Nothing ->
                    dict
        )
        SeqDict.empty
        userIds
