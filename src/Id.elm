module Id exposing
    ( AnyGuildOrDmIdNoThread(..)
    , ChannelId(..)
    , ChannelMessageId(..)
    , DiscordGuildOrDmId(..)
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
    , fromInt
    , fromString
    , mapAnyGuildOrDmId
    , mapGuildOrDmId
    , nextId
    , threadRouteToMessageId
    , threadRouteWithMessage
    , threadRouteWithoutMessage
    , toInt
    , toString
    )

import Discord.Id
import DiscordDmChannelId exposing (DiscordDmChannelId)
import List.Extra
import SeqDict exposing (SeqDict)


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm (Id UserId)


type DiscordGuildOrDmId a
    = DiscordGuildOrDmId_Guild a (Discord.Id.Id Discord.Id.GuildId) (Discord.Id.Id Discord.Id.ChannelId)
    | DiscordGuildOrDmId_Dm DiscordDmChannelId


type AnyGuildOrDmIdNoThread a
    = GuildOrDmId GuildOrDmId
    | DiscordGuildOrDmId (DiscordGuildOrDmId a)


type ThreadRoute
    = NoThread
    | ViewThread (Id ChannelMessageId)


mapGuildOrDmId : (a -> b) -> DiscordGuildOrDmId a -> DiscordGuildOrDmId b
mapGuildOrDmId mapFunc discordGuildOrDmId =
    case discordGuildOrDmId of
        DiscordGuildOrDmId_Guild a guildId channelId ->
            DiscordGuildOrDmId_Guild (mapFunc a) guildId channelId

        DiscordGuildOrDmId_Dm discordDmChannelId ->
            DiscordGuildOrDmId_Dm discordDmChannelId


mapAnyGuildOrDmId : (a -> b) -> AnyGuildOrDmIdNoThread a -> AnyGuildOrDmIdNoThread b
mapAnyGuildOrDmId mapFunc discordGuildOrDmId =
    case discordGuildOrDmId of
        GuildOrDmId a ->
            GuildOrDmId a

        DiscordGuildOrDmId a ->
            mapGuildOrDmId mapFunc a |> DiscordGuildOrDmId


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
