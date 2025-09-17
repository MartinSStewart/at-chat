module Evergreen.V76.Message exposing (..)

import Evergreen.V76.Emoji
import Evergreen.V76.FileStatus
import Evergreen.V76.Id
import Evergreen.V76.NonemptySet
import Evergreen.V76.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V76.Id.Id Evergreen.V76.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V76.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V76.Emoji.Emoji (Evergreen.V76.NonemptySet.NonemptySet (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V76.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V76.Id.Id Evergreen.V76.FileStatus.FileId) Evergreen.V76.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId) (SeqDict.SeqDict Evergreen.V76.Emoji.Emoji (Evergreen.V76.NonemptySet.NonemptySet (Evergreen.V76.Id.Id Evergreen.V76.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
