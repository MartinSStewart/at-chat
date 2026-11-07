module Evergreen.V421.Thread exposing (..)

import Date
import Effect.Time
import Evergreen.V421.Discord
import Evergreen.V421.Drawing
import Evergreen.V421.Id
import Evergreen.V421.IdArray
import Evergreen.V421.Message
import Evergreen.V421.MessageArray
import Evergreen.V421.OneToOne
import Evergreen.V421.Slack
import Evergreen.V421.VisibleMessages
import SeqDict


type alias FrontendThread =
    { messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    }


type alias LastTypedAt channelId =
    { channelId : channelId
    , threadRoute : Evergreen.V421.Id.ThreadRouteWithMaybeMessage
    , time : Effect.Time.Posix
    }


type alias DiscordFrontendThread =
    { messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId)
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId))
    }


type alias FrontendGenericThread userId channelId =
    { messages : Evergreen.V421.MessageArray.MessageArray Evergreen.V421.Id.ThreadMessageId userId channelId
    , visibleMessages : Evergreen.V421.VisibleMessages.VisibleMessages Evergreen.V421.Id.ThreadMessageId
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing userId)
    }


type alias SlackFrontendThread =
    FrontendGenericThread (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId)


type alias BackendThread =
    { messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ChannelId))
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Id.Id Evergreen.V421.Id.UserId))
    }


type alias DiscordBackendThread =
    { messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId) (Evergreen.V421.Discord.Id Evergreen.V421.Discord.ChannelId))
    , linkedMessageIds : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.Discord.Id Evergreen.V421.Discord.MessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId)
    , dateDividerDrawings : SeqDict.SeqDict Date.Date (Evergreen.V421.Drawing.Drawing (Evergreen.V421.Discord.Id Evergreen.V421.Discord.UserId))
    }


type alias SlackBackendThread =
    { messages : Evergreen.V421.IdArray.IdArray Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Message.Message Evergreen.V421.Id.ThreadMessageId (Evergreen.V421.Slack.Id Evergreen.V421.Slack.UserId) (Evergreen.V421.Slack.Id Evergreen.V421.Slack.ChannelId))
    , linkedMessageIds : Evergreen.V421.OneToOne.OneToOne (Evergreen.V421.Slack.Id Evergreen.V421.Slack.MessageId) (Evergreen.V421.Id.Id Evergreen.V421.Id.ThreadMessageId)
    }
