module Evergreen.V77.Route exposing (..)

import Effect.Lamdera
import Evergreen.V77.Id
import Evergreen.V77.SecretId
import Evergreen.V77.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelMessageId) (Maybe (Evergreen.V77.Id.Id Evergreen.V77.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V77.Id.Id Evergreen.V77.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V77.SecretId.SecretId Evergreen.V77.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V77.Id.Id Evergreen.V77.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V77.Id.Id Evergreen.V77.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V77.Slack.OAuthCode, Effect.Lamdera.SessionId ))
