module Evergreen.V190.Message exposing (..)

import Array
import Evergreen.V190.Embed
import Evergreen.V190.Emoji
import Evergreen.V190.FileStatus
import Evergreen.V190.Id
import Evergreen.V190.NonemptySet
import Evergreen.V190.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V190.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V190.Emoji.Emoji (Evergreen.V190.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V190.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V190.Id.Id Evergreen.V190.FileStatus.FileId) Evergreen.V190.FileStatus.FileData
    , embeds : Array.Array Evergreen.V190.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V190.Emoji.Emoji (Evergreen.V190.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
