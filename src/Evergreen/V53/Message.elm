module Evergreen.V53.Message exposing (..)

import Evergreen.V53.Emoji
import Evergreen.V53.FileStatus
import Evergreen.V53.Id
import Evergreen.V53.NonemptySet
import Evergreen.V53.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V53.Id.Id Evergreen.V53.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V53.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V53.Emoji.Emoji (Evergreen.V53.NonemptySet.NonemptySet (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V53.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V53.Id.Id Evergreen.V53.FileStatus.FileId) Evergreen.V53.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId) (SeqDict.SeqDict Evergreen.V53.Emoji.Emoji (Evergreen.V53.NonemptySet.NonemptySet (Evergreen.V53.Id.Id Evergreen.V53.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
