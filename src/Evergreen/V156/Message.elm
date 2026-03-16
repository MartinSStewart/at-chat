module Evergreen.V156.Message exposing (..)

import Array
import Evergreen.V156.Emoji
import Evergreen.V156.FileStatus
import Evergreen.V156.Id
import Evergreen.V156.NonemptySet
import Evergreen.V156.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V156.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V156.Emoji.Emoji (Evergreen.V156.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V156.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V156.Id.Id Evergreen.V156.FileStatus.FileId) Evergreen.V156.FileStatus.FileData
    , embeds : Array.Array Evergreen.V156.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V156.Emoji.Emoji (Evergreen.V156.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
