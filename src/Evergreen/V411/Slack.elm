module Evergreen.V411.Slack exposing (..)

import Effect.Time
import Evergreen.V411.NonemptySet
import List.Nonempty
import SeqDict


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


type FileId
    = FileId Never


type alias SlackData =
    { cookie : SlackCookie
    , tokens : List.Nonempty.Nonempty SlackToken
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


type alias File =
    { id : Id FileId
    , name : String
    , mimetype : String
    , size : Int
    , url : String
    }


type MessageContent
    = TextMessage
        { text : String
        , blocks : List RichTextElement
        , files : List File
        }
    | JoinedChannel


type InThread
    = NotAReply
    | ReplyTo (Id MessageId)
    | BroadcastReplyTo (Id MessageId)


type alias Reaction =
    { name : String
    , users : List (Id UserId)
    }


type alias Message =
    { id : Id MessageId
    , createdAt : Effect.Time.Posix
    , user : Id UserId
    , content : MessageContent
    , inThread : InThread
    , replyCount : Int
    , reactions : List Reaction
    }


type CustomEmojiSource
    = CustomEmojiImage String
    | CustomEmojiAlias String


type WebsocketEvent
    = WebsocketRelayReady
    | WebsocketHello
    | WebsocketMessageCreated String Message
    | WebsocketMessageChanged String Message Effect.Time.Posix
    | WebsocketMessageDeleted String (Id UserId) (Id MessageId)
    | WebsocketReactionAdded
        { user : Id UserId
        , reaction : String
        , channel : String
        , messageId : Id MessageId
        }
    | WebsocketReactionRemoved
        { user : Id UserId
        , reaction : String
        , channel : String
        , messageId : Id MessageId
        }
    | WebsocketUserChanged User
    | WebsocketTeamRenamed String
    | WebsocketTeamDomainChanged String
    | WebsocketConversationsChanged
    | WebsocketChannelRenamed (Id ChannelId) String
    | WebsocketCustomEmojiAdded String CustomEmojiSource
    | WebsocketOtherEvent


type alias Team =
    { id : Id TeamId
    , name : String
    , domain : String
    , icon : Maybe String
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


type alias History =
    { messages : List Message
    , replies : SeqDict.SeqDict (Id MessageId) (List Message)
    }


type alias DmChannel =
    { id : Id DmChannelId
    , members : Evergreen.V411.NonemptySet.NonemptySet (Id UserId)
    }
