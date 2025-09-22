module Evergreen.V94.Route exposing (..)

import Evergreen.V94.Id
import Evergreen.V94.SecretId
import Evergreen.V94.SessionIdHash
import Evergreen.V94.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelMessageId) (Maybe (Evergreen.V94.Id.Id Evergreen.V94.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V94.Id.Id Evergreen.V94.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V94.SecretId.SecretId Evergreen.V94.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V94.Id.Id Evergreen.V94.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V94.Id.Id Evergreen.V94.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V94.Slack.OAuthCode, Evergreen.V94.SessionIdHash.SessionIdHash ))
