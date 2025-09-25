module Evergreen.V108.Message exposing (..)

import Evergreen.V108.Emoji
import Evergreen.V108.FileStatus
import Evergreen.V108.Id
import Evergreen.V108.NonemptySet
import Evergreen.V108.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId =
    { createdAt : Time.Posix
    , createdBy : Evergreen.V108.Id.Id Evergreen.V108.Id.UserId
    , content : List.Nonempty.Nonempty Evergreen.V108.RichText.RichText
    , reactions : SeqDict.SeqDict Evergreen.V108.Emoji.Emoji (Evergreen.V108.NonemptySet.NonemptySet (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V108.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V108.Id.Id Evergreen.V108.FileStatus.FileId) Evergreen.V108.FileStatus.FileData
    }


type Message messageId
    = UserTextMessage (UserTextMessageData messageId)
    | UserJoinedMessage Time.Posix (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId) (SeqDict.SeqDict Evergreen.V108.Emoji.Emoji (Evergreen.V108.NonemptySet.NonemptySet (Evergreen.V108.Id.Id Evergreen.V108.Id.UserId)))
    | DeletedMessage Time.Posix


type MessageState messageId
    = MessageLoaded (Message messageId)
    | MessageUnloaded
