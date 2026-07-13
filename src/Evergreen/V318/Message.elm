module Evergreen.V318.Message exposing (..)

import Array
import Evergreen.V318.Drawing
import Evergreen.V318.Embed
import Evergreen.V318.Emoji
import Evergreen.V318.FileStatus
import Evergreen.V318.Id
import Evergreen.V318.NonemptySet
import Evergreen.V318.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V318.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V318.Emoji.EmojiOrCustomEmoji (Evergreen.V318.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V318.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) Evergreen.V318.FileStatus.FileData
    , embeds : Array.Array Evergreen.V318.Embed.Embed
    , timestampDrawings : Evergreen.V318.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V318.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V318.Id.Id Evergreen.V318.FileStatus.FileId) (Evergreen.V318.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V318.Drawing.Drawing userId)
    }


type alias CallStartedData userId =
    { startedAt : Time.Posix
    , endedAt : Maybe Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V318.Emoji.EmojiOrCustomEmoji (Evergreen.V318.NonemptySet.NonemptySet userId)
    , timestampDrawings : Evergreen.V318.Drawing.Drawing userId
    , cardDrawings : Evergreen.V318.Drawing.Drawing userId
    }


type alias GameStartedData userId =
    { startedAt : Time.Posix
    , startedBy : userId
    , reactions : SeqDict.SeqDict Evergreen.V318.Emoji.EmojiOrCustomEmoji (Evergreen.V318.NonemptySet.NonemptySet userId)
    , gameType : GameType
    , timestampDrawings : Evergreen.V318.Drawing.Drawing userId
    , cardDrawings : Evergreen.V318.Drawing.Drawing userId
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V318.Emoji.EmojiOrCustomEmoji (Evergreen.V318.NonemptySet.NonemptySet userId)) (Evergreen.V318.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted (CallStartedData userId)
    | GameStarted (GameStartedData userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
