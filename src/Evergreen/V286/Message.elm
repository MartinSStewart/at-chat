module Evergreen.V286.Message exposing (..)

import Array
import Evergreen.V286.Drawing
import Evergreen.V286.Embed
import Evergreen.V286.Emoji
import Evergreen.V286.FileStatus
import Evergreen.V286.Id
import Evergreen.V286.NonemptySet
import Evergreen.V286.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V286.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V286.Emoji.EmojiOrCustomEmoji (Evergreen.V286.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V286.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) Evergreen.V286.FileStatus.FileData
    , embeds : Array.Array Evergreen.V286.Embed.Embed
    , timestampDrawings : Evergreen.V286.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V286.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V286.Id.Id Evergreen.V286.FileStatus.FileId) (Evergreen.V286.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V286.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V286.Emoji.EmojiOrCustomEmoji (Evergreen.V286.NonemptySet.NonemptySet userId)) (Evergreen.V286.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V286.Emoji.EmojiOrCustomEmoji (Evergreen.V286.NonemptySet.NonemptySet userId)) (Evergreen.V286.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V286.Emoji.EmojiOrCustomEmoji (Evergreen.V286.NonemptySet.NonemptySet userId)) (Evergreen.V286.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
