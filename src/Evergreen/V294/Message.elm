module Evergreen.V294.Message exposing (..)

import Array
import Evergreen.V294.Drawing
import Evergreen.V294.Embed
import Evergreen.V294.Emoji
import Evergreen.V294.FileStatus
import Evergreen.V294.Id
import Evergreen.V294.NonemptySet
import Evergreen.V294.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V294.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V294.Emoji.EmojiOrCustomEmoji (Evergreen.V294.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V294.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) Evergreen.V294.FileStatus.FileData
    , embeds : Array.Array Evergreen.V294.Embed.Embed
    , timestampDrawings : Evergreen.V294.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V294.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId) (Evergreen.V294.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V294.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V294.Emoji.EmojiOrCustomEmoji (Evergreen.V294.NonemptySet.NonemptySet userId)) (Evergreen.V294.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V294.Emoji.EmojiOrCustomEmoji (Evergreen.V294.NonemptySet.NonemptySet userId)) (Evergreen.V294.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V294.Emoji.EmojiOrCustomEmoji (Evergreen.V294.NonemptySet.NonemptySet userId)) (Evergreen.V294.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
