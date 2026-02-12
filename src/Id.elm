module Id exposing
    ( AnyGuildOrDmId(..)
    , ChannelId(..)
    , ChannelMessageId(..)
    , DiscordGuildOrDmId(..)
    , DiscordGuildOrDmId_DmData
    , GuildId(..)
    , GuildOrDmId(..)
    , Id(..)
    , InviteLinkId(..)
    , ThreadMessageId(..)
    , ThreadRoute(..)
    , ThreadRouteWithMaybeMessage(..)
    , ThreadRouteWithMessage(..)
    , UserId(..)
    , changeType
    , codec
    , fromInt
    , fromString
    , nextId
    , threadRouteToMessageId
    , threadRouteWithMessage
    , threadRouteWithoutMessage
    , toInt
    , toString
    )

import Codec exposing (Codec)
import Discord.Id
import List.Extra
import SeqDict exposing (SeqDict)


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm (Id UserId)


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild (Discord.Id.Id Discord.Id.UserId) (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId)
    | DiscordGuildOrDmId_Dm DiscordGuildOrDmId_DmData


type alias DiscordGuildOrDmId_DmData =
    { currentUserId : Discord.Id.Id Discord.Id.UserId
    , channelId : Discord.Id.Id Discord.Id.PrivateChannelId
    }


type AnyGuildOrDmId
    = GuildOrDmId GuildOrDmId
    | DiscordGuildOrDmId DiscordGuildOrDmId


type ThreadRoute
    = NoThread
    | ViewThread (Id ChannelMessageId)


threadRouteWithoutMessage : ThreadRouteWithMessage -> ThreadRoute
threadRouteWithoutMessage threadRoute =
    case threadRoute of
        ViewThreadWithMessage threadId _ ->
            ViewThread threadId

        NoThreadWithMessage _ ->
            NoThread


threadRouteToMessageId : ThreadRouteWithMessage -> Id ChannelMessageId
threadRouteToMessageId threadRoute =
    case threadRoute of
        ViewThreadWithMessage _ messageId ->
            changeType messageId

        NoThreadWithMessage messageId ->
            messageId


threadRouteWithMessage : Id ChannelMessageId -> ThreadRoute -> ThreadRouteWithMessage
threadRouteWithMessage messageId threadRoute =
    case threadRoute of
        ViewThread threadId ->
            ViewThreadWithMessage threadId (changeType messageId)

        NoThread ->
            NoThreadWithMessage messageId


type ThreadRouteWithMessage
    = NoThreadWithMessage (Id ChannelMessageId)
    | ViewThreadWithMessage (Id ChannelMessageId) (Id ThreadMessageId)


type ThreadRouteWithMaybeMessage
    = NoThreadWithMaybeMessage (Maybe (Id ChannelMessageId))
    | ViewThreadWithMaybeMessage (Id ChannelMessageId) (Maybe (Id ThreadMessageId))


type UserId
    = UserId Never


type GuildId
    = GuildId Never


type ChannelId
    = ChannelId Never


type ChannelMessageId
    = ChannelMessageId Never


type ThreadMessageId
    = ThreadMessageId Never


type InviteLinkId
    = InviteLinkId Never


type Id a
    = Id Int


nextId : SeqDict (Id a) b -> Id a
nextId dict =
    case SeqDict.keys dict |> List.Extra.maximumWith (\(Id a) (Id b) -> compare a b) of
        Just (Id value) ->
            Id (value + 1)

        Nothing ->
            Id 0


fromInt : Int -> Id a
fromInt =
    Id


toInt : Id a -> Int
toInt (Id int) =
    int


fromString : String -> Maybe (Id a)
fromString string =
    String.toInt string |> Maybe.map Id


toString : Id a -> String
toString (Id a) =
    String.fromInt a


changeType : Id a -> Id b
changeType (Id a) =
    Id a


codec : Codec (Id a)
codec =
    Codec.map fromInt toInt Codec.int
