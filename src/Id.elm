module Id exposing
    ( ChannelId(..)
    , ChannelMessageId
    , GuildId(..)
    , GuildOrDmId(..)
    , GuildOrDmIdNoThread(..)
    , GuildOrDmIdWithMaybeMessage(..)
    , Id(..)
    , InviteLinkId(..)
    , ThreadMessageId
    , ThreadRoute(..)
    , ThreadRouteWithMaybeMessage(..)
    , ThreadRouteWithMessage(..)
    , UserId(..)
    , changeType
    , fromInt
    , fromString
    , guildOrDmIdSetThreadRoute
    , guildOrDmIdWithoutMaybeMessage
    , increment
    , nextId
    , toInt
    , toString
    )

import List.Extra
import SeqDict exposing (SeqDict)


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId) ThreadRoute
    | GuildOrDmId_Dm (Id UserId) ThreadRoute


type GuildOrDmIdNoThread
    = GuildOrDmId_Guild_NoThread (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm_NoThread (Id UserId)


type GuildOrDmIdWithMaybeMessage
    = GuildOrDmId_Guild_WithMaybeMessage (Id GuildId) (Id ChannelId) ThreadRouteWithMaybeMessage
    | GuildOrDmId_Dm_WithMaybeMessage (Id UserId) ThreadRouteWithMaybeMessage


guildOrDmIdWithoutMaybeMessage : GuildOrDmIdWithMaybeMessage -> GuildOrDmId
guildOrDmIdWithoutMaybeMessage a =
    case a of
        GuildOrDmId_Guild_WithMaybeMessage guildId channelId threadRoute ->
            GuildOrDmId_Guild guildId channelId (threadWithoutMaybeMessage threadRoute)

        GuildOrDmId_Dm_WithMaybeMessage otherUserId threadRoute ->
            GuildOrDmId_Dm otherUserId (threadWithoutMaybeMessage threadRoute)


threadWithoutMaybeMessage : ThreadRouteWithMaybeMessage -> ThreadRoute
threadWithoutMaybeMessage a =
    case a of
        NoThreadWithMaybeMessage _ ->
            NoThread

        ViewThreadWithMaybeMessage channelMessageId _ ->
            ViewThread channelMessageId


guildOrDmIdSetThreadRoute : GuildOrDmId -> ThreadRoute -> GuildOrDmId
guildOrDmIdSetThreadRoute guildOrDmId threadRoute =
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId _ ->
            GuildOrDmId_Guild guildId channelId threadRoute

        GuildOrDmId_Dm otherUserId _ ->
            GuildOrDmId_Dm otherUserId threadRoute


type ThreadRoute
    = NoThread
    | ViewThread (Id ChannelMessageId)


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


increment : Id a -> Id a
increment (Id id) =
    id + 1 |> Id


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
