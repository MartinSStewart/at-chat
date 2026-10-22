module Evergreen.V408.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V408.Discord
import Evergreen.V408.Drawing
import Evergreen.V408.Id
import Evergreen.V408.IdArray
import Evergreen.V408.Message
import Evergreen.V408.MessageArray
import Evergreen.V408.OneToOne
import Evergreen.V408.Slack
import Evergreen.V408.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V408.MessageArray.MessageArray Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId)
    , visibleMessages : Evergreen.V408.VisibleMessages.VisibleMessages Evergreen.V408.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V408.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V408.MessageArray.MessageArray Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId)
    , visibleMessages : Evergreen.V408.VisibleMessages.VisibleMessages Evergreen.V408.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V408.MessageArray.MessageArray Evergreen.V408.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V408.VisibleMessages.VisibleMessages Evergreen.V408.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Id.Id Evergreen.V408.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId) (Evergreen.V408.Discord.Id Evergreen.V408.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V408.OneToOne.OneToOne (Evergreen.V408.Discord.Id Evergreen.V408.Discord.MessageId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V408.Drawing.Drawing (Evergreen.V408.Discord.Id Evergreen.V408.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V408.IdArray.IdArray Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Message.Message Evergreen.V408.Id.ThreadMessageId (Evergreen.V408.Slack.Id Evergreen.V408.Slack.UserId) (Evergreen.V408.Slack.Id Evergreen.V408.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V408.OneToOne.OneToOne (Evergreen.V408.Slack.Id Evergreen.V408.Slack.MessageId) (Evergreen.V408.Id.Id Evergreen.V408.Id.ThreadMessageId)
    }
