module Evergreen.V426.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V426.Discord
import Evergreen.V426.Drawing
import Evergreen.V426.Id
import Evergreen.V426.IdArray
import Evergreen.V426.Message
import Evergreen.V426.MessageArray
import Evergreen.V426.OneToOne
import Evergreen.V426.Slack
import Evergreen.V426.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V426.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId)
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V426.MessageArray.MessageArray Evergreen.V426.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V426.VisibleMessages.VisibleMessages Evergreen.V426.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Id.Id Evergreen.V426.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId) (Evergreen.V426.Discord.Id Evergreen.V426.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.Discord.Id Evergreen.V426.Discord.MessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V426.Drawing.Drawing (Evergreen.V426.Discord.Id Evergreen.V426.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V426.IdArray.IdArray Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Message.Message Evergreen.V426.Id.ThreadMessageId (Evergreen.V426.Slack.Id Evergreen.V426.Slack.UserId) (Evergreen.V426.Slack.Id Evergreen.V426.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V426.OneToOne.OneToOne (Evergreen.V426.Slack.Id Evergreen.V426.Slack.MessageId) (Evergreen.V426.Id.Id Evergreen.V426.Id.ThreadMessageId)
    }
