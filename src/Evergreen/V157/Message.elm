module Evergreen.V157.Message exposing (..)

import Array
import Evergreen.V157.Emoji
import Evergreen.V157.FileStatus
import Evergreen.V157.Id
import Evergreen.V157.NonemptySet
import Evergreen.V157.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V157.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V157.Emoji.Emoji (Evergreen.V157.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V157.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V157.Id.Id Evergreen.V157.FileStatus.FileId) Evergreen.V157.FileStatus.FileData
    , embeds : Array.Array Evergreen.V157.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V157.Emoji.Emoji (Evergreen.V157.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
