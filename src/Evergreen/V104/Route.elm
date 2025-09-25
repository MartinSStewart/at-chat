module Evergreen.V104.Route exposing (..)

import Evergreen.V104.Id
import Evergreen.V104.SecretId
import Evergreen.V104.SessionIdHash
import Evergreen.V104.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelMessageId) (Maybe (Evergreen.V104.Id.Id Evergreen.V104.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V104.Id.Id Evergreen.V104.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V104.SecretId.SecretId Evergreen.V104.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V104.Id.Id Evergreen.V104.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V104.Id.Id Evergreen.V104.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V104.Slack.OAuthCode, Evergreen.V104.SessionIdHash.SessionIdHash ))
