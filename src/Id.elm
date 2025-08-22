module Id exposing
    ( ChannelId(..)
    , GuildId(..)
    , GuildOrDmId(..)
    , Id(..)
    , InviteLinkId(..)
    , MessageId
    , ThreadRoute(..)
    , UserId(..)
    , fromInt
    , fromString
    , guildOrDmIdSetThreadRoute
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


guildOrDmIdSetThreadRoute : GuildOrDmId -> ThreadRoute -> GuildOrDmId
guildOrDmIdSetThreadRoute guildOrDmId threadRoute =
    case guildOrDmId of
        GuildOrDmId_Guild guildId channelId _ ->
            GuildOrDmId_Guild guildId channelId threadRoute

        GuildOrDmId_Dm otherUserId _ ->
            GuildOrDmId_Dm otherUserId threadRoute


type ThreadRoute
    = NoThread
    | ViewThread (Id MessageId)


type UserId
    = UserId Never


type GuildId
    = GuildId Never


type ChannelId
    = ChannelId Never


type MessageId
    = MessageId Never


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
