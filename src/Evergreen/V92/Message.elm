module Evergreen.V92.Message exposing (..)

import Evergreen.V92.Emoji
import Evergreen.V92.FileStatus
import Evergreen.V92.Id
import Evergreen.V92.NonemptySet
import Evergreen.V92.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V92.Id.Id Evergreen.V92.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V92.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V92.Emoji.Emoji (Evergreen.V92.NonemptySet.NonemptySet (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V92.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V92.Id.Id Evergreen.V92.FileStatus.FileId) Evergreen.V92.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId) (SeqDict.SeqDict Evergreen.V92.Emoji.Emoji (Evergreen.V92.NonemptySet.NonemptySet (Evergreen.V92.Id.Id Evergreen.V92.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
