module Evergreen.V302.Message exposing (..)

import Array
import Evergreen.V302.Drawing
import Evergreen.V302.Embed
import Evergreen.V302.Emoji
import Evergreen.V302.FileStatus
import Evergreen.V302.Id
import Evergreen.V302.NonemptySet
import Evergreen.V302.RichText
import List.Nonempty
import SeqDict
import Time


type Game
    = Game_Go
    | Game_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V302.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V302.Emoji.EmojiOrCustomEmoji (Evergreen.V302.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V302.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) Evergreen.V302.FileStatus.FileData
    , embeds : Array.Array Evergreen.V302.Embed.Embed
    , timestampDrawings : Evergreen.V302.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V302.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V302.Id.Id Evergreen.V302.FileStatus.FileId) (Evergreen.V302.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V302.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V302.Emoji.EmojiOrCustomEmoji (Evergreen.V302.NonemptySet.NonemptySet userId)) (Evergreen.V302.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V302.Emoji.EmojiOrCustomEmoji (Evergreen.V302.NonemptySet.NonemptySet userId)) (Evergreen.V302.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V302.Emoji.EmojiOrCustomEmoji (Evergreen.V302.NonemptySet.NonemptySet userId)) (Evergreen.V302.Drawing.Drawing userId) Game


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
