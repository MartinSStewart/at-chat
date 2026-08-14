module Id exposing
    ( AnyGuildOrDmId(..)
    , ChannelId(..)
    , ChannelMessageId(..)
    , CustomEmojiId(..)
    , DiscordGuildOrDmId(..)
    , ExportChannelId(..)
    , GamePublicId(..)
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
    , VideoNodeId(..)
    , Viewing_ChannelId
    , Viewing_ChannelThreadId
    , Viewing_DiscordChannelId
    , Viewing_DiscordChannelThreadId
    , Viewing_DiscordDmId
    , Viewing_DmId
    , Viewing_DmThreadId
    , changeType
    , fromInt
    , fromString
    , increment
    , nextId
    , threadRouteToMessageId
    , threadRouteWithMessage
    , threadRouteWithoutMaybeMessage
    , threadRouteWithoutMessage
    , toInt
    , toString
    )

import Discord
import List.Extra
import SeqDict exposing (SeqDict)


type GuildOrDmId
    = GuildOrDmId_Guild Viewing_ChannelId
    | GuildOrDmId_Dm Viewing_DmId


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild Viewing_DiscordChannelId
    | DiscordGuildOrDmId_Dm Viewing_DiscordDmId


type alias Viewing_DmId =
    { otherUserId : Id UserId
    }


type alias Viewing_DmThreadId =
    { otherUserId : Id UserId
    , threadId : Id ChannelMessageId
    }


type alias Viewing_DiscordDmId =
    { currentUserId : Discord.Id Discord.UserId
    , channelId : Discord.Id Discord.PrivateChannelId
    }


type alias Viewing_ChannelId =
    { guildId : Id GuildId
    , channelId : Id ChannelId
    }


type alias Viewing_ChannelThreadId =
    { guildId : Id GuildId
    , channelId : Id ChannelId
    , threadId : Id ChannelMessageId
    }


type alias Viewing_DiscordChannelId =
    { guildId : Discord.Id Discord.GuildId
    , channelId : Discord.Id Discord.ChannelId
    , currentUserId : Discord.Id Discord.UserId
    }


type alias Viewing_DiscordChannelThreadId =
    { guildId : Discord.Id Discord.GuildId
    , channelId : Discord.Id Discord.ChannelId
    , currentUserId : Discord.Id Discord.UserId
    , threadId : Id ChannelMessageId
    }


type AnyGuildOrDmId
    = GuildOrDmId GuildOrDmId
    | DiscordGuildOrDmId DiscordGuildOrDmId


{-| Identifies a channel that the user wants to export the messages of.
-}
type ExportChannelId
    = ExportChannel_Guild (Id GuildId) (Id ChannelId)
    | ExportChannel_Discord (Discord.Id Discord.UserId) (Discord.Id Discord.GuildId) (Discord.Id Discord.ChannelId)
    | ExportChannel_Dm (Id UserId)
    | ExportChannel_DiscordDm (Discord.Id Discord.UserId) (Discord.Id Discord.PrivateChannelId)


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


threadRouteWithoutMaybeMessage : ThreadRouteWithMaybeMessage -> ThreadRoute
threadRouteWithoutMaybeMessage threadRoute =
    case threadRoute of
        ViewThreadWithMaybeMessage threadId _ ->
            ViewThread threadId

        NoThreadWithMaybeMessage _ ->
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


type VideoNodeId
    = VideoNodeId Never


type GamePublicId
    = GoMatchPublicId Never


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


increment : Id a -> Id a
increment (Id id) =
    Id (id + 1)
