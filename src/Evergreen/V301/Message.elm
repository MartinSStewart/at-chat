module Evergreen.V301.Message exposing (..)

import Array
import Evergreen.V301.Drawing
import Evergreen.V301.Embed
import Evergreen.V301.Emoji
import Evergreen.V301.FileStatus
import Evergreen.V301.Id
import Evergreen.V301.NonemptySet
import Evergreen.V301.RichText
import List.Nonempty
import SeqDict
import Time


type Game
    = Game_Go
    | Game_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V301.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V301.Emoji.EmojiOrCustomEmoji (Evergreen.V301.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V301.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) Evergreen.V301.FileStatus.FileData
    , embeds : Array.Array Evergreen.V301.Embed.Embed
    , timestampDrawings : Evergreen.V301.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V301.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.FileStatus.FileId) (Evergreen.V301.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V301.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V301.Emoji.EmojiOrCustomEmoji (Evergreen.V301.NonemptySet.NonemptySet userId)) (Evergreen.V301.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V301.Emoji.EmojiOrCustomEmoji (Evergreen.V301.NonemptySet.NonemptySet userId)) (Evergreen.V301.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V301.Emoji.EmojiOrCustomEmoji (Evergreen.V301.NonemptySet.NonemptySet userId)) (Evergreen.V301.Drawing.Drawing userId) Game


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
