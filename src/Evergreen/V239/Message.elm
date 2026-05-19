module Evergreen.V239.Message exposing (..)

import Array
import Evergreen.V239.Embed
import Evergreen.V239.Emoji
import Evergreen.V239.FileStatus
import Evergreen.V239.Id
import Evergreen.V239.NonemptySet
import Evergreen.V239.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V239.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V239.Emoji.EmojiOrCustomEmoji (Evergreen.V239.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V239.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V239.Id.Id Evergreen.V239.FileStatus.FileId) Evergreen.V239.FileStatus.FileData
    , embeds : Array.Array Evergreen.V239.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V239.Emoji.EmojiOrCustomEmoji (Evergreen.V239.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V239.Emoji.EmojiOrCustomEmoji (Evergreen.V239.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V239.Emoji.EmojiOrCustomEmoji (Evergreen.V239.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V239.Emoji.EmojiOrCustomEmoji (Evergreen.V239.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
