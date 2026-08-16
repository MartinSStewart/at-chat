module Evergreen.V353.Id exposing (..)

import Evergreen.V353.Discord


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


type alias Viewing_ChannelId =
    { guildId : Id GuildId
    , channelId : Id ChannelId
    }


type alias Viewing_DmId =
    { otherUserId : Id UserId
    }


type GuildOrDmId
    = GuildOrDmId_Guild Viewing_ChannelId
    | GuildOrDmId_Dm Viewing_DmId


type alias Viewing_DiscordChannelId =
    { guildId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId
    , channelId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId
    , currentUserId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId
    }


type alias Viewing_DiscordDmId =
    { currentUserId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId
    , channelId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId
    }


type DiscordGuildOrDmId
    = DiscordGuildOrDmId_Guild Viewing_DiscordChannelId
    | DiscordGuildOrDmId_Dm Viewing_DiscordDmId


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
    | ExportChannel_Discord (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId)
    | ExportChannel_Dm (Id UserId)
    | ExportChannel_DiscordDm (Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId) (Evergreen.V353.Discord.Id Evergreen.V353.Discord.PrivateChannelId)


type alias Viewing_DmThreadId =
    { otherUserId : Id UserId
    , threadId : Id ChannelMessageId
    }


type alias Viewing_ChannelThreadId =
    { guildId : Id GuildId
    , channelId : Id ChannelId
    , threadId : Id ChannelMessageId
    }


type alias Viewing_DiscordChannelThreadId =
    { guildId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.GuildId
    , channelId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.ChannelId
    , currentUserId : Evergreen.V353.Discord.Id Evergreen.V353.Discord.UserId
    , threadId : Id ChannelMessageId
    }


type ThreadRouteWithMaybeMessage
    = NoThreadWithMaybeMessage (Maybe (Id ChannelMessageId))
    | ViewThreadWithMaybeMessage (Id ChannelMessageId) (Maybe (Id ThreadMessageId))
