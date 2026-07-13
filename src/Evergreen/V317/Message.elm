module Evergreen.V317.Message exposing (..)

import Array
import Evergreen.V317.Drawing
import Evergreen.V317.Embed
import Evergreen.V317.Emoji
import Evergreen.V317.FileStatus
import Evergreen.V317.Id
import Evergreen.V317.NonemptySet
import Evergreen.V317.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V317.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V317.Emoji.EmojiOrCustomEmoji (Evergreen.V317.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V317.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) Evergreen.V317.FileStatus.FileData
    , embeds : Array.Array Evergreen.V317.Embed.Embed
    , timestampDrawings : Evergreen.V317.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V317.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.FileStatus.FileId) (Evergreen.V317.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V317.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V317.Emoji.EmojiOrCustomEmoji (Evergreen.V317.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V317.Drawing.Drawing userId
    , cardDrawings : Evergreen.V317.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V317.Emoji.EmojiOrCustomEmoji (Evergreen.V317.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V317.Drawing.Drawing userId
    , cardDrawings : Evergreen.V317.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V317.Emoji.EmojiOrCustomEmoji (Evergreen.V317.NonemptySet.NonemptySet userId)) (Evergreen.V317.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
