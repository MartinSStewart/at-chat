module Evergreen.V97.Route exposing (..)

import Evergreen.V97.Id
import Evergreen.V97.SecretId
import Evergreen.V97.SessionIdHash
import Evergreen.V97.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelMessageId) (Maybe (Evergreen.V97.Id.Id Evergreen.V97.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V97.Id.Id Evergreen.V97.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V97.SecretId.SecretId Evergreen.V97.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V97.Id.Id Evergreen.V97.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V97.Slack.OAuthCode, Evergreen.V97.SessionIdHash.SessionIdHash ))
