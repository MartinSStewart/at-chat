module Evergreen.V425.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V425.Discord
import Evergreen.V425.Drawing
import Evergreen.V425.Id
import Evergreen.V425.IdArray
import Evergreen.V425.Message
import Evergreen.V425.MessageArray
import Evergreen.V425.OneToOne
import Evergreen.V425.Slack
import Evergreen.V425.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V425.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId)
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V425.MessageArray.MessageArray Evergreen.V425.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V425.VisibleMessages.VisibleMessages Evergreen.V425.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId) (Evergreen.V425.Discord.Id Evergreen.V425.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.Discord.Id Evergreen.V425.Discord.MessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V425.Drawing.Drawing (Evergreen.V425.Discord.Id Evergreen.V425.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V425.IdArray.IdArray Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Message.Message Evergreen.V425.Id.ThreadMessageId (Evergreen.V425.Slack.Id Evergreen.V425.Slack.UserId) (Evergreen.V425.Slack.Id Evergreen.V425.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V425.OneToOne.OneToOne (Evergreen.V425.Slack.Id Evergreen.V425.Slack.MessageId) (Evergreen.V425.Id.Id Evergreen.V425.Id.ThreadMessageId)
    }
