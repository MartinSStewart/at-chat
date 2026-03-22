module Evergreen.V166.Message exposing (..)

import Array
import Evergreen.V166.Emoji
import Evergreen.V166.FileStatus
import Evergreen.V166.Id
import Evergreen.V166.NonemptySet
import Evergreen.V166.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V166.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V166.Emoji.Emoji (Evergreen.V166.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V166.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.FileStatus.FileId) Evergreen.V166.FileStatus.FileData
    , embeds : Array.Array Evergreen.V166.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V166.Emoji.Emoji (Evergreen.V166.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
