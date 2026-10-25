module Evergreen.V411.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V411.Discord
import Evergreen.V411.Drawing
import Evergreen.V411.Id
import Evergreen.V411.IdArray
import Evergreen.V411.Message
import Evergreen.V411.MessageArray
import Evergreen.V411.OneToOne
import Evergreen.V411.Slack
import Evergreen.V411.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V411.MessageArray.MessageArray Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId)
    , visibleMessages : Evergreen.V411.VisibleMessages.VisibleMessages Evergreen.V411.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V411.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V411.MessageArray.MessageArray Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId)
    , visibleMessages : Evergreen.V411.VisibleMessages.VisibleMessages Evergreen.V411.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V411.MessageArray.MessageArray Evergreen.V411.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V411.VisibleMessages.VisibleMessages Evergreen.V411.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Id.Id Evergreen.V411.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId) (Evergreen.V411.Discord.Id Evergreen.V411.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V411.OneToOne.OneToOne (Evergreen.V411.Discord.Id Evergreen.V411.Discord.MessageId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V411.Drawing.Drawing (Evergreen.V411.Discord.Id Evergreen.V411.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V411.IdArray.IdArray Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Message.Message Evergreen.V411.Id.ThreadMessageId (Evergreen.V411.Slack.Id Evergreen.V411.Slack.UserId) (Evergreen.V411.Slack.Id Evergreen.V411.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V411.OneToOne.OneToOne (Evergreen.V411.Slack.Id Evergreen.V411.Slack.MessageId) (Evergreen.V411.Id.Id Evergreen.V411.Id.ThreadMessageId)
    }
