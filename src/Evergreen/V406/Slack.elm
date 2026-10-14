module Evergreen.V406.Slack exposing (..)

import Effect.Time
import Evergreen.V406.NonemptySet
import List.Nonempty


type TeamId
    = TeamId Never


type Id a
    = Id String


type DmChannelId
    = DmChannelId Never


type UserId
    = UserId Never


type ChannelId
    = ChannelId Never


type HttpError
    = SlackError String
    | RateLimited
    | BadStatus Int String
    | BadBody String
    | Timeout
    | NetworkError
    | BadUrl String


type MessageId
    = MessageId Never


type alias User =
    { id : Id UserId
    , teamId : Id TeamId
    , name : String
    , realName : String
    , displayName : String
    , image : String
    , isBot : Bool
    , deleted : Bool
    }


type SlackToken
    = SlackToken String


type SlackCookie
    = SlackCookie String


type alias SlackData =
    { cookie : SlackCookie
    , tokens : List.Nonempty.Nonempty SlackToken
    }


type alias Team =
    { id : Id TeamId
    , name : String
    , domain : String
    , icon : String
    }


type alias UserBoot =
    { self : User
    , team : Team
    }


type alias Channel =
    { id : Id ChannelId
    , name : String
    , isPrivate : Bool
    }


type alias Style =
    { bold : Bool
    , italic : Bool
    , strike : Bool
    , code : Bool
    }


type RichTextInline
    = RichText_Text
        { text : String
        , style : Style
        }
    | RichText_Link
        { url : String
        , text : String
        , style : Style
        }
    | RichText_Emoji
        { name : String
        , unicode : String
        , style : Style
        }
    | RichText_User (Id UserId)
    | RichText_Channel (Id ChannelId)
    | RichText_Broadcast String
    | RichText_Date
        { timestamp : Int
        , fallback : String
        }


type RichTextElement
    = RichTextSection (List RichTextInline)
    | RichTextPreformatted (List RichTextInline)
    | RichTextQuote (List RichTextInline)
    | RichTextList (List (List RichTextInline))


type MessageContent
    = TextMessage
        { text : String
        , blocks : List RichTextElement
        }
    | JoinedChannel


type alias Message =
    { id : Id MessageId
    , createdAt : Effect.Time.Posix
    , user : Id UserId
    , content : MessageContent
    }


type alias DmChannel =
    { id : Id DmChannelId
    , members : Evergreen.V406.NonemptySet.NonemptySet (Id UserId)
    }
