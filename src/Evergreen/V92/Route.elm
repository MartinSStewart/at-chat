module Evergreen.V92.Route exposing (..)

import Evergreen.V92.Id
import Evergreen.V92.SecretId
import Evergreen.V92.SessionIdHash
import Evergreen.V92.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelMessageId) (Maybe (Evergreen.V92.Id.Id Evergreen.V92.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V92.Id.Id Evergreen.V92.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V92.SecretId.SecretId Evergreen.V92.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V92.Id.Id Evergreen.V92.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V92.Slack.OAuthCode, Evergreen.V92.SessionIdHash.SessionIdHash ))
