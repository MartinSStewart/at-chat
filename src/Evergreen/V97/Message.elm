module Evergreen.V97.Message exposing (..)

import Evergreen.V97.Emoji
import Evergreen.V97.FileStatus
import Evergreen.V97.Id
import Evergreen.V97.NonemptySet
import Evergreen.V97.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V97.Id.Id Evergreen.V97.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V97.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V97.Emoji.Emoji (Evergreen.V97.NonemptySet.NonemptySet (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V97.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V97.Id.Id Evergreen.V97.FileStatus.FileId) Evergreen.V97.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId) (SeqDict.SeqDict Evergreen.V97.Emoji.Emoji (Evergreen.V97.NonemptySet.NonemptySet (Evergreen.V97.Id.Id Evergreen.V97.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
