module Evergreen.V60.Message exposing (..)

import Evergreen.V60.Emoji
import Evergreen.V60.FileStatus
import Evergreen.V60.Id
import Evergreen.V60.NonemptySet
import Evergreen.V60.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V60.Id.Id Evergreen.V60.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V60.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V60.Emoji.Emoji (Evergreen.V60.NonemptySet.NonemptySet (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V60.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V60.Id.Id Evergreen.V60.FileStatus.FileId) Evergreen.V60.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId) (SeqDict.SeqDict Evergreen.V60.Emoji.Emoji (Evergreen.V60.NonemptySet.NonemptySet (Evergreen.V60.Id.Id Evergreen.V60.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
