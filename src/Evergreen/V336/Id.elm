module Evergreen.V336.Id exposing (..)

import Evergreen.V336.Discord


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
    { currentUserId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId
    , channelId : Evergreen.V336.Discord.Id Evergreen.V336.Discord.PrivateChannelId
    }


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId)
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
    | ExportChannel_Discord (Evergreen.V336.Discord.Id Evergreen.V336.Discord.UserId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.GuildId) (Evergreen.V336.Discord.Id Evergreen.V336.Discord.ChannelId)


type ThreadRouteWithMaybeMessage
    = NoThreadWithMaybeMessage (Maybe (Id ChannelMessageId))
    | ViewThreadWithMaybeMessage (Id ChannelMessageId) (Maybe (Id ThreadMessageId))
