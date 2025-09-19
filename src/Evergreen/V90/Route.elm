module Evergreen.V90.Route exposing (..)

import Effect.Lamdera
import Evergreen.V90.Id
import Evergreen.V90.SecretId
import Evergreen.V90.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelMessageId) (Maybe (Evergreen.V90.Id.Id Evergreen.V90.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V90.Id.Id Evergreen.V90.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V90.SecretId.SecretId Evergreen.V90.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V90.Id.Id Evergreen.V90.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V90.Id.Id Evergreen.V90.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V90.Slack.OAuthCode, Effect.Lamdera.SessionId ))
