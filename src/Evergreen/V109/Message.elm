module Evergreen.V109.Message exposing (..)

import Evergreen.V109.Emoji
import Evergreen.V109.FileStatus
import Evergreen.V109.Id
import Evergreen.V109.NonemptySet
import Evergreen.V109.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V109.Id.Id Evergreen.V109.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V109.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V109.Emoji.Emoji (Evergreen.V109.NonemptySet.NonemptySet (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V109.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V109.Id.Id Evergreen.V109.FileStatus.FileId) Evergreen.V109.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId) (SeqDict.SeqDict Evergreen.V109.Emoji.Emoji (Evergreen.V109.NonemptySet.NonemptySet (Evergreen.V109.Id.Id Evergreen.V109.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
