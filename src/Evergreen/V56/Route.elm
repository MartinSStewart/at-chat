module Evergreen.V56.Route exposing (..)

import Effect.Lamdera
import Evergreen.V56.Id
import Evergreen.V56.SecretId
import Evergreen.V56.Slack


type ChannelRoute
    = ChannelRoute (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId) Evergreen.V56.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V56.Id.Id Evergreen.V56.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V56.SecretId.SecretId Evergreen.V56.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V56.Id.Id Evergreen.V56.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V56.Id.Id Evergreen.V56.Id.UserId) Evergreen.V56.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V56.Slack.OAuthCode, Effect.Lamdera.SessionId ))
