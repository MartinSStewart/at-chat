module Evergreen.V101.Route exposing (..)

import Evergreen.V101.Id
import Evergreen.V101.SecretId
import Evergreen.V101.SessionIdHash
import Evergreen.V101.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelMessageId) (Maybe (Evergreen.V101.Id.Id Evergreen.V101.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V101.Id.Id Evergreen.V101.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V101.SecretId.SecretId Evergreen.V101.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V101.Id.Id Evergreen.V101.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V101.Id.Id Evergreen.V101.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V101.Slack.OAuthCode, Evergreen.V101.SessionIdHash.SessionIdHash ))
