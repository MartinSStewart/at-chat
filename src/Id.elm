module Id exposing
    ( AnyGuildOrDmId(..)
    , ChannelId(..)
    , ChannelMessageId(..)
    , CustomEmojiId(..)
    , DiscordGuildOrDmId(..)
    , DiscordGuildOrDmId_DmData
    , GuildId(..)
    , GuildOrDmId(..)
    , Id(..)
    , InviteLinkId(..)
    , StickerId(..)
    , ThreadMessageId(..)
    , ThreadRoute(..)
    , ThreadRouteWithMaybeMessage(..)
    , ThreadRouteWithMessage(..)
    , UserId(..)
    , changeType
    , decrement
    , fromInt
    , fromString
    , increment
    , maximum
    , minimum
    , nextId
    , threadRouteToMessageId
    , threadRouteWithMessage
    , threadRouteWithoutMessage
    , toInt
    , toString
    )

import Discord
import List.Extra
import SeqDict exposing (SeqDict)


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm (Id UserId)


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild (Discord.Id Discord.UserId) (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId)
    | DiscordGuildOrDmId_Dm DiscordGuildOrDmId_DmData


type alias DiscordGuildOrDmId_DmData =
    { currentUserId : Discord.Id Discord.UserId
    , channelId : Discord.Id Discord.PrivateChannelId
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


type StickerId
    = StickerId Never


type CustomEmojiId
    = CustomEmojiId Never


type Id a
    = Id Int


increment : Id a -> Id a
increment (Id id) =
    Id (id + 1)


decrement : Id a -> Id a
decrement (Id id) =
    Id (id - 1)


minimum : Id a -> Id a -> Id a
minimum (Id a) (Id b) =
    min a b |> Id


maximum : Id a -> Id a -> Id a
maximum (Id a) (Id b) =
    max a b |> Id


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
