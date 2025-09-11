module Evergreen.V54.Message exposing (..)

import Evergreen.V54.Emoji
import Evergreen.V54.FileStatus
import Evergreen.V54.Id
import Evergreen.V54.NonemptySet
import Evergreen.V54.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V54.Id.Id Evergreen.V54.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V54.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V54.Emoji.Emoji (Evergreen.V54.NonemptySet.NonemptySet (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V54.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V54.Id.Id Evergreen.V54.FileStatus.FileId) Evergreen.V54.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId) (SeqDict.SeqDict Evergreen.V54.Emoji.Emoji (Evergreen.V54.NonemptySet.NonemptySet (Evergreen.V54.Id.Id Evergreen.V54.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
