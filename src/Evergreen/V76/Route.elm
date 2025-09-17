module Evergreen.V76.Route exposing (..)

import Effect.Lamdera
import Evergreen.V76.Id
import Evergreen.V76.SecretId
import Evergreen.V76.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelMessageId) (Maybe (Evergreen.V76.Id.Id Evergreen.V76.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V76.Id.Id Evergreen.V76.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V76.SecretId.SecretId Evergreen.V76.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V76.Id.Id Evergreen.V76.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V76.Slack.OAuthCode, Effect.Lamdera.SessionId ))
