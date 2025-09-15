module Evergreen.V61.Route exposing (..)

import Effect.Lamdera
import Evergreen.V61.Id
import Evergreen.V61.SecretId
import Evergreen.V61.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelMessageId) (Maybe (Evergreen.V61.Id.Id Evergreen.V61.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V61.Id.Id Evergreen.V61.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V61.SecretId.SecretId Evergreen.V61.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V61.Id.Id Evergreen.V61.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V61.Id.Id Evergreen.V61.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V61.Slack.OAuthCode, Effect.Lamdera.SessionId ))
