module Evergreen.V422.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V422.Discord
import Evergreen.V422.Drawing
import Evergreen.V422.Id
import Evergreen.V422.IdArray
import Evergreen.V422.Message
import Evergreen.V422.MessageArray
import Evergreen.V422.OneToOne
import Evergreen.V422.Slack
import Evergreen.V422.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V422.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId)
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V422.MessageArray.MessageArray Evergreen.V422.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V422.VisibleMessages.VisibleMessages Evergreen.V422.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Id.Id Evergreen.V422.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId) (Evergreen.V422.Discord.Id Evergreen.V422.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.Discord.Id Evergreen.V422.Discord.MessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V422.Drawing.Drawing (Evergreen.V422.Discord.Id Evergreen.V422.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V422.IdArray.IdArray Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Message.Message Evergreen.V422.Id.ThreadMessageId (Evergreen.V422.Slack.Id Evergreen.V422.Slack.UserId) (Evergreen.V422.Slack.Id Evergreen.V422.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V422.OneToOne.OneToOne (Evergreen.V422.Slack.Id Evergreen.V422.Slack.MessageId) (Evergreen.V422.Id.Id Evergreen.V422.Id.ThreadMessageId)
    }
