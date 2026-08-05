module Evergreen.V345.Id exposing (..)

import Evergreen.V345.Discord


type Id a
    = Id Int


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


type GamePublicId
    = GoMatchPublicId Never


type GuildOrDmId
    = GuildOrDmId_Guild (Id GuildId) (Id ChannelId)
    | GuildOrDmId_Dm (Id UserId)


type alias DiscordGuildOrDmId_DmData =
    { currentUserId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId
    , channelId : Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId
    }


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId)
    | DiscordGuildOrDmId_Dm DiscordGuildOrDmId_DmData


type AnyGuildOrDmId
    = GuildOrDmId GuildOrDmId
    | DiscordGuildOrDmId DiscordGuildOrDmId


type ThreadRoute
    = NoThread
    | ViewThread (Id ChannelMessageId)


type ThreadRouteWithMessage
    = NoThreadWithMessage (Id ChannelMessageId)
    | ViewThreadWithMessage (Id ChannelMessageId) (Id ThreadMessageId)


type CustomEmojiId
    = CustomEmojiId Never


type StickerId
    = StickerId Never


type ExportChannelId
    = ExportChannel_Guild (Id GuildId) (Id ChannelId)
    | ExportChannel_Discord (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.GuildId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.ChannelId)
    | ExportChannel_Dm (Id UserId)
    | ExportChannel_DiscordDm (Evergreen.V345.Discord.Id Evergreen.V345.Discord.UserId) (Evergreen.V345.Discord.Id Evergreen.V345.Discord.PrivateChannelId)


type ThreadRouteWithMaybeMessage
    = NoThreadWithMaybeMessage (Maybe (Id ChannelMessageId))
    | ViewThreadWithMaybeMessage (Id ChannelMessageId) (Maybe (Id ThreadMessageId))
