module Evergreen.V287.Route exposing (..)

import Evergreen.V287.Discord
import Evergreen.V287.DmChannel
import Evergreen.V287.Id
import Evergreen.V287.Pagination
import Evergreen.V287.SecretId
import Evergreen.V287.SessionIdHash
import Evergreen.V287.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId) (Maybe (Evergreen.V287.Id.Id Evergreen.V287.Id.ThreadMessageId)) ShowMembersTab


type DmChannelHeaderTab
    = DmChannelHeaderTab_VoiceChat
    | DmChannelHeaderTab_Go (Maybe (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId))
    | DmChannelHeaderTab_ChannelDescription
    | DmChannelHeaderTab_Draw


type ChannelRoute
    = ChannelRoute (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelId)
    | GuildSettingsRoute
    | JoinRoute (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.InviteLinkId)


type DiscordChannelRoute
    = DiscordChannel_ChannelRoute (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId) ThreadRouteWithFriends (Maybe DmChannelHeaderTab)
    | DiscordChannel_NewChannelRoute
    | DiscordChannel_EditChannelRoute (Evergreen.V287.Discord.Id Evergreen.V287.Discord.ChannelId)
    | DiscordChannel_GuildSettingsRoute


type alias DiscordGuildRouteData =
    { currentDiscordUserId : Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId
    , guildId : Evergreen.V287.Discord.Id Evergreen.V287.Discord.GuildId
    , channelRoute : DiscordChannelRoute
    }


type alias DmRouteData =
    { channelId : Evergreen.V287.DmChannel.DmChannelId
    , threadRoute : ThreadRouteWithFriends
    , tab : Maybe DmChannelHeaderTab
    }


type alias DiscordDmRouteData =
    { currentDiscordUserId : Evergreen.V287.Discord.Id Evergreen.V287.Discord.UserId
    , channelId : Evergreen.V287.Discord.Id Evergreen.V287.Discord.PrivateChannelId
    , viewingMessage : Maybe (Evergreen.V287.Id.Id Evergreen.V287.Id.ChannelMessageId)
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
        { highlightLog : Maybe (Evergreen.V287.Id.Id Evergreen.V287.Pagination.ItemId)
        }
    | GuildRoute (Evergreen.V287.Id.Id Evergreen.V287.Id.GuildId) ChannelRoute
    | DiscordGuildRoute DiscordGuildRouteData
    | DmRoute DmRouteData
    | DiscordDmRoute DiscordDmRouteData
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V287.Slack.OAuthCode, Evergreen.V287.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
    | LinkDiscord (Result LinkDiscordError Evergreen.V287.Discord.UserAuth)
    | PublicGoMatchRoute (Evergreen.V287.SecretId.SecretId Evergreen.V287.Id.GoMatchPublicId)
