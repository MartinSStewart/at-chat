module Evergreen.V59.Route exposing (..)

import Effect.Lamdera
import Evergreen.V59.Id
import Evergreen.V59.SecretId
import Evergreen.V59.Slack


type ChannelRoute
    = ChannelRoute (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId) Evergreen.V59.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V59.Id.Id Evergreen.V59.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V59.SecretId.SecretId Evergreen.V59.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V59.Id.Id Evergreen.V59.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V59.Id.Id Evergreen.V59.Id.UserId) Evergreen.V59.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V59.Slack.OAuthCode, Effect.Lamdera.SessionId ))
