module Evergreen.V263.Route exposing (..)

import Evergreen.V263.Discord
import Evergreen.V263.DmChannel
import Evergreen.V263.Id
import Evergreen.V263.Pagination
import Evergreen.V263.SecretId
import Evergreen.V263.SessionIdHash
import Evergreen.V263.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId) (Maybe (Evergreen.V263.Id.Id Evergreen.V263.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription


type ChannelRoute
    = ChannelRoute (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V263.Discord.Id Evergreen.V263.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId
    , guildId : Evergreen.V263.Discord.Id Evergreen.V263.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V263.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V263.Discord.Id Evergreen.V263.Discord.UserId
    , channelId : Evergreen.V263.Discord.Id Evergreen.V263.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V263.Id.Id Evergreen.V263.Id.ChannelMessageId)
    , showMembersTab : ShowMembersTab
    , tab : Maybe DmChannelHeaderTab
    }


type LinkDiscordError
    = LinkDiscordExpired
    | LinkDiscordServerError
    | LinkDiscordInvalidData


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe (Evergreen.V263.Id.Id Evergreen.V263.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V263.Id.Id Evergreen.V263.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V263.Slack.OAuthCode, Evergreen.V263.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V263.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V263.SecretId.SecretId Evergreen.V263.Id.GoMatchPublicId)
