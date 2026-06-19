module Evergreen.V290.Message exposing (..)

import Array
import Evergreen.V290.Drawing
import Evergreen.V290.Embed
import Evergreen.V290.Emoji
import Evergreen.V290.FileStatus
import Evergreen.V290.Id
import Evergreen.V290.NonemptySet
import Evergreen.V290.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V290.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V290.Emoji.EmojiOrCustomEmoji (Evergreen.V290.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V290.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) Evergreen.V290.FileStatus.FileData
    , embeds : Array.Array Evergreen.V290.Embed.Embed
    , timestampDrawings : Evergreen.V290.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V290.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.FileStatus.FileId) (Evergreen.V290.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V290.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V290.Emoji.EmojiOrCustomEmoji (Evergreen.V290.NonemptySet.NonemptySet userId)) (Evergreen.V290.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V290.Emoji.EmojiOrCustomEmoji (Evergreen.V290.NonemptySet.NonemptySet userId)) (Evergreen.V290.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V290.Emoji.EmojiOrCustomEmoji (Evergreen.V290.NonemptySet.NonemptySet userId)) (Evergreen.V290.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
