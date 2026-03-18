module Evergreen.V158.Message exposing (..)

import Array
import Evergreen.V158.Emoji
import Evergreen.V158.FileStatus
import Evergreen.V158.Id
import Evergreen.V158.NonemptySet
import Evergreen.V158.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V158.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V158.Emoji.Emoji (Evergreen.V158.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V158.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V158.Id.Id Evergreen.V158.FileStatus.FileId) Evergreen.V158.FileStatus.FileData
    , embeds : Array.Array Evergreen.V158.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V158.Emoji.Emoji (Evergreen.V158.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
