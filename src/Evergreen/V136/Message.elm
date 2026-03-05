module Evergreen.V136.Message exposing (..)

import Evergreen.V136.Emoji
import Evergreen.V136.FileStatus
import Evergreen.V136.Id
import Evergreen.V136.NonemptySet
import Evergreen.V136.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V136.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V136.Emoji.Emoji (Evergreen.V136.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V136.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V136.Id.Id Evergreen.V136.FileStatus.FileId) Evergreen.V136.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V136.Emoji.Emoji (Evergreen.V136.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
