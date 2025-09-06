module Evergreen.V49.Route exposing (..)

import Effect.Lamdera
import Evergreen.V49.Id
import Evergreen.V49.SecretId
import Evergreen.V49.Slack


type ChannelRoute
    = ChannelRoute (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId) Evergreen.V49.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V49.Id.Id Evergreen.V49.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V49.SecretId.SecretId Evergreen.V49.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V49.Id.Id Evergreen.V49.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V49.Id.Id Evergreen.V49.Id.UserId) Evergreen.V49.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V49.Slack.OAuthCode, Effect.Lamdera.SessionId ))
