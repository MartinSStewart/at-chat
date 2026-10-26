module Evergreen.V414.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V414.Discord
import Evergreen.V414.Drawing
import Evergreen.V414.Id
import Evergreen.V414.IdArray
import Evergreen.V414.Message
import Evergreen.V414.MessageArray
import Evergreen.V414.OneToOne
import Evergreen.V414.Slack
import Evergreen.V414.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V414.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId)
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V414.MessageArray.MessageArray Evergreen.V414.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V414.VisibleMessages.VisibleMessages Evergreen.V414.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V414.IdArray.IdArray Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Message.Message Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Id.Id Evergreen.V414.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V414.IdArray.IdArray Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Message.Message Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId) (Evergreen.V414.Discord.Id Evergreen.V414.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V414.OneToOne.OneToOne (Evergreen.V414.Discord.Id Evergreen.V414.Discord.MessageId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V414.Drawing.Drawing (Evergreen.V414.Discord.Id Evergreen.V414.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V414.IdArray.IdArray Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Message.Message Evergreen.V414.Id.ThreadMessageId (Evergreen.V414.Slack.Id Evergreen.V414.Slack.UserId) (Evergreen.V414.Slack.Id Evergreen.V414.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V414.OneToOne.OneToOne (Evergreen.V414.Slack.Id Evergreen.V414.Slack.MessageId) (Evergreen.V414.Id.Id Evergreen.V414.Id.ThreadMessageId)
    }
