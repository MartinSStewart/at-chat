module Evergreen.V299.Message exposing (..)

import Array
import Evergreen.V299.Drawing
import Evergreen.V299.Embed
import Evergreen.V299.Emoji
import Evergreen.V299.FileStatus
import Evergreen.V299.Id
import Evergreen.V299.NonemptySet
import Evergreen.V299.RichText
import List.Nonempty
import SeqDict
import Time


type Game
    = Game_Go
    | Game_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V299.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V299.Emoji.EmojiOrCustomEmoji (Evergreen.V299.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V299.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) Evergreen.V299.FileStatus.FileData
    , embeds : Array.Array Evergreen.V299.Embed.Embed
    , timestampDrawings : Evergreen.V299.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V299.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.FileStatus.FileId) (Evergreen.V299.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V299.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V299.Emoji.EmojiOrCustomEmoji (Evergreen.V299.NonemptySet.NonemptySet userId)) (Evergreen.V299.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V299.Emoji.EmojiOrCustomEmoji (Evergreen.V299.NonemptySet.NonemptySet userId)) (Evergreen.V299.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V299.Emoji.EmojiOrCustomEmoji (Evergreen.V299.NonemptySet.NonemptySet userId)) (Evergreen.V299.Drawing.Drawing userId) Game


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
