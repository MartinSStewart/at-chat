module Evergreen.V102.Route exposing (..)

import Evergreen.V102.Id
import Evergreen.V102.SecretId
import Evergreen.V102.SessionIdHash
import Evergreen.V102.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelMessageId) (Maybe (Evergreen.V102.Id.Id Evergreen.V102.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V102.Id.Id Evergreen.V102.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V102.SecretId.SecretId Evergreen.V102.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V102.Id.Id Evergreen.V102.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V102.Id.Id Evergreen.V102.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V102.Slack.OAuthCode, Evergreen.V102.SessionIdHash.SessionIdHash ))
