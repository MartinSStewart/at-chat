module Evergreen.V297.Message exposing (..)

import Array
import Evergreen.V297.Drawing
import Evergreen.V297.Embed
import Evergreen.V297.Emoji
import Evergreen.V297.FileStatus
import Evergreen.V297.Id
import Evergreen.V297.NonemptySet
import Evergreen.V297.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V297.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V297.Emoji.EmojiOrCustomEmoji (Evergreen.V297.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V297.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) Evergreen.V297.FileStatus.FileData
    , embeds : Array.Array Evergreen.V297.Embed.Embed
    , timestampDrawings : Evergreen.V297.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V297.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.FileStatus.FileId) (Evergreen.V297.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V297.Drawing.Drawing userId)
    }


type Game
    = Game_Go
    | Game_WordSpellingGame


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V297.Emoji.EmojiOrCustomEmoji (Evergreen.V297.NonemptySet.NonemptySet userId)) (Evergreen.V297.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V297.Emoji.EmojiOrCustomEmoji (Evergreen.V297.NonemptySet.NonemptySet userId)) (Evergreen.V297.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V297.Emoji.EmojiOrCustomEmoji (Evergreen.V297.NonemptySet.NonemptySet userId)) (Evergreen.V297.Drawing.Drawing userId) Game


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
