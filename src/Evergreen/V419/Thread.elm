module Evergreen.V419.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V419.Discord
import Evergreen.V419.Drawing
import Evergreen.V419.Id
import Evergreen.V419.IdArray
import Evergreen.V419.Message
import Evergreen.V419.MessageArray
import Evergreen.V419.OneToOne
import Evergreen.V419.Slack
import Evergreen.V419.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V419.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId)
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V419.MessageArray.MessageArray Evergreen.V419.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V419.VisibleMessages.VisibleMessages Evergreen.V419.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Id.Id Evergreen.V419.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId) (Evergreen.V419.Discord.Id Evergreen.V419.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.Discord.Id Evergreen.V419.Discord.MessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V419.Drawing.Drawing (Evergreen.V419.Discord.Id Evergreen.V419.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V419.IdArray.IdArray Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Message.Message Evergreen.V419.Id.ThreadMessageId (Evergreen.V419.Slack.Id Evergreen.V419.Slack.UserId) (Evergreen.V419.Slack.Id Evergreen.V419.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V419.OneToOne.OneToOne (Evergreen.V419.Slack.Id Evergreen.V419.Slack.MessageId) (Evergreen.V419.Id.Id Evergreen.V419.Id.ThreadMessageId)
    }
