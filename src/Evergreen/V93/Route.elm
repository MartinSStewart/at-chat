module Evergreen.V93.Route exposing (..)

import Evergreen.V93.Id
import Evergreen.V93.SecretId
import Evergreen.V93.SessionIdHash
import Evergreen.V93.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelMessageId) (Maybe (Evergreen.V93.Id.Id Evergreen.V93.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V93.Id.Id Evergreen.V93.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V93.SecretId.SecretId Evergreen.V93.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V93.Id.Id Evergreen.V93.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V93.Id.Id Evergreen.V93.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V93.Slack.OAuthCode, Evergreen.V93.SessionIdHash.SessionIdHash ))
