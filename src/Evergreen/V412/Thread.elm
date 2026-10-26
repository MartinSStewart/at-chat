module Evergreen.V412.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V412.Discord
import Evergreen.V412.Drawing
import Evergreen.V412.Id
import Evergreen.V412.IdArray
import Evergreen.V412.Message
import Evergreen.V412.MessageArray
import Evergreen.V412.OneToOne
import Evergreen.V412.Slack
import Evergreen.V412.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V412.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId)
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V412.MessageArray.MessageArray Evergreen.V412.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V412.VisibleMessages.VisibleMessages Evergreen.V412.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId) (Evergreen.V412.Discord.Id Evergreen.V412.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.Discord.Id Evergreen.V412.Discord.MessageId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V412.Drawing.Drawing (Evergreen.V412.Discord.Id Evergreen.V412.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V412.IdArray.IdArray Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Message.Message Evergreen.V412.Id.ThreadMessageId (Evergreen.V412.Slack.Id Evergreen.V412.Slack.UserId) (Evergreen.V412.Slack.Id Evergreen.V412.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V412.OneToOne.OneToOne (Evergreen.V412.Slack.Id Evergreen.V412.Slack.MessageId) (Evergreen.V412.Id.Id Evergreen.V412.Id.ThreadMessageId)
    }
