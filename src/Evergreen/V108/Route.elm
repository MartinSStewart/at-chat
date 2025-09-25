module Evergreen.V108.Route exposing (..)

import Evergreen.V108.Id
import Evergreen.V108.SecretId
import Evergreen.V108.SessionIdHash
import Evergreen.V108.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelMessageId) (Maybe (Evergreen.V108.Id.Id Evergreen.V108.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V108.Id.Id Evergreen.V108.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V108.SecretId.SecretId Evergreen.V108.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V108.Id.Id Evergreen.V108.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V108.Slack.OAuthCode, Evergreen.V108.SessionIdHash.SessionIdHash ))
