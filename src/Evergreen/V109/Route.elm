module Evergreen.V109.Route exposing (..)

import Evergreen.V109.Id
import Evergreen.V109.SecretId
import Evergreen.V109.SessionIdHash
import Evergreen.V109.Slack


type ShowMembersTab
    = ShowMembersTab
    | HideMembersTab


type ThreadRouteWithFriends
    = NoThreadWithFriends (Maybe (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId)) ShowMembersTab
    | ViewThreadWithFriends (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelMessageId) (Maybe (Evergreen.V109.Id.Id Evergreen.V109.Id.ThreadMessageId)) ShowMembersTab


type ChannelRoute
    = ChannelRoute (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId) ThreadRouteWithFriends
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V109.Id.Id Evergreen.V109.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V109.SecretId.SecretId Evergreen.V109.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V109.Id.Id Evergreen.V109.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) ThreadRouteWithFriends
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V109.Slack.OAuthCode, Evergreen.V109.SessionIdHash.SessionIdHash ))
    | TextEditorRoute
