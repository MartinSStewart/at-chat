module Evergreen.V295.Message exposing (..)

import Array
import Evergreen.V295.Drawing
import Evergreen.V295.Embed
import Evergreen.V295.Emoji
import Evergreen.V295.FileStatus
import Evergreen.V295.Id
import Evergreen.V295.NonemptySet
import Evergreen.V295.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V295.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V295.Emoji.EmojiOrCustomEmoji (Evergreen.V295.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V295.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) Evergreen.V295.FileStatus.FileData
    , embeds : Array.Array Evergreen.V295.Embed.Embed
    , timestampDrawings : Evergreen.V295.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V295.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.FileStatus.FileId) (Evergreen.V295.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V295.Drawing.Drawing userId)
    }


type Game
    = Game_Go
    | Game_WordSpellingGame


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V295.Emoji.EmojiOrCustomEmoji (Evergreen.V295.NonemptySet.NonemptySet userId)) (Evergreen.V295.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V295.Emoji.EmojiOrCustomEmoji (Evergreen.V295.NonemptySet.NonemptySet userId)) (Evergreen.V295.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V295.Emoji.EmojiOrCustomEmoji (Evergreen.V295.NonemptySet.NonemptySet userId)) (Evergreen.V295.Drawing.Drawing userId) Game


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
