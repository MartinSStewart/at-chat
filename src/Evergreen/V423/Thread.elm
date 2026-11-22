module Evergreen.V423.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V423.Discord
import Evergreen.V423.Drawing
import Evergreen.V423.Id
import Evergreen.V423.IdArray
import Evergreen.V423.Message
import Evergreen.V423.MessageArray
import Evergreen.V423.OneToOne
import Evergreen.V423.Slack
import Evergreen.V423.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V423.MessageArray.MessageArray Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId)
    , visibleMessages : Evergreen.V423.VisibleMessages.VisibleMessages Evergreen.V423.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V423.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V423.MessageArray.MessageArray Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId)
    , visibleMessages : Evergreen.V423.VisibleMessages.VisibleMessages Evergreen.V423.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V423.MessageArray.MessageArray Evergreen.V423.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V423.VisibleMessages.VisibleMessages Evergreen.V423.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId) (Evergreen.V423.Discord.Id Evergreen.V423.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V423.OneToOne.OneToOne (Evergreen.V423.Discord.Id Evergreen.V423.Discord.MessageId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V423.Drawing.Drawing (Evergreen.V423.Discord.Id Evergreen.V423.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V423.IdArray.IdArray Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Message.Message Evergreen.V423.Id.ThreadMessageId (Evergreen.V423.Slack.Id Evergreen.V423.Slack.UserId) (Evergreen.V423.Slack.Id Evergreen.V423.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V423.OneToOne.OneToOne (Evergreen.V423.Slack.Id Evergreen.V423.Slack.MessageId) (Evergreen.V423.Id.Id Evergreen.V423.Id.ThreadMessageId)
    }
