module Evergreen.V114.Slack exposing (..)

import Effect.Time
import String.Nonempty


type OAuthCode
    = OAuthCode String


type ClientSecret
    = ClientSecret String


type ChannelId
    = ChannelId Never


type Id a
    = Id String


type UserId
    = UserId Never


type TeamId
    = TeamId Never


type AuthToken
    = SlackAuth String


type alias CurrentUser =
    { userId : Id UserId
    , teamId : Id TeamId
    , url : String
    , team : String
    , user : String
    , enterpriseId : Maybe String
    }


type alias Team =
    { id : Id TeamId
    , name : String
    , domain : String
    , image132 : String
    }


type alias User =
    { id : Id UserId
    , name : String
    , isBot : Bool
    , isDeleted : Bool
    , profile : String
    }


type alias NormalChannelData =
    { id : Id ChannelId
    , isArchived : Bool
    , name : String
    , isMember : Bool
    , isPrivate : Bool
    , created : Effect.Time.Posix
    }


type alias ImChannelData =
    { id : Id ChannelId
    , isArchived : Bool
    , user : Id UserId
    , isUserDeleted : Bool
    , isOrgShared : Bool
    , created : Effect.Time.Posix
    }


type Channel
    = NormalChannel NormalChannelData
    | ImChannel ImChannelData


type MessageId
    = MessageId Never


type alias RichText_Text_Data =
    { text : String
    , italic : Bool
    , bold : Bool
    , code : Bool
    , strikethrough : Bool
    }


type alias RichText_Emoji_Data =
    { name : String
    , unicode : String.Nonempty.NonemptyString
    }


type RichTextElement
    = RichText_Text RichText_Text_Data
    | RichText_Emoji RichText_Emoji_Data
    | RichText_UserMention (Id UserId)


type BlockElement
    = RichTextSection (List RichTextElement)
    | RichTextPreformattedSection (List RichTextElement)


type Block
    = RichTextBlock (List BlockElement)


type MessageType
    = UserJoinedMessage
    | UserMessage (Id MessageId) (List Block)
    | JoinerNotificationForInviter
    | BotMessage


type alias Message =
    { createdBy : Id UserId
    , createdAt : Effect.Time.Posix
    , messageType : MessageType
    }


type alias TokenResponse =
    { botAccessToken : AuthToken
    , userAccessToken : AuthToken
    , userId : Id UserId
    , teamId : Id TeamId
    , teamName : String
    }
