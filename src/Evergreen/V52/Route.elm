module Evergreen.V52.Route exposing (..)

import Effect.Lamdera
import Evergreen.V52.Id
import Evergreen.V52.SecretId
import Evergreen.V52.Slack


type ChannelRoute
    = ChannelRoute (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId) Evergreen.V52.Id.ThreadRouteWithMaybeMessage
    | NewChannelRoute
    | EditChannelRoute (Evergreen.V52.Id.Id Evergreen.V52.Id.ChannelId)
    | InviteLinkCreatorRoute
    | JoinRoute (Evergreen.V52.SecretId.SecretId Evergreen.V52.Id.InviteLinkId)


type Route
    = HomePageRoute
    | AdminRoute
        { highlightLog : Maybe Int
        }
    | GuildRoute (Evergreen.V52.Id.Id Evergreen.V52.Id.GuildId) ChannelRoute
    | DmRoute (Evergreen.V52.Id.Id Evergreen.V52.Id.UserId) Evergreen.V52.Id.ThreadRouteWithMaybeMessage
    | AiChatRoute
    | SlackOAuthRedirect (Result () ( Evergreen.V52.Slack.OAuthCode, Effect.Lamdera.SessionId ))
