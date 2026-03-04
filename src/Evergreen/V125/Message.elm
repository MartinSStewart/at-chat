module Evergreen.V125.Message exposing (..)

import Evergreen.V125.Emoji
import Evergreen.V125.FileStatus
import Evergreen.V125.Id
import Evergreen.V125.NonemptySet
import Evergreen.V125.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V125.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V125.Emoji.Emoji (Evergreen.V125.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V125.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.FileStatus.FileId) Evergreen.V125.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V125.Emoji.Emoji (Evergreen.V125.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
