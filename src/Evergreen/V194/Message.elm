module Evergreen.V194.Message exposing (..)

import Array
import Evergreen.V194.Embed
import Evergreen.V194.Emoji
import Evergreen.V194.FileStatus
import Evergreen.V194.Id
import Evergreen.V194.NonemptySet
import Evergreen.V194.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V194.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V194.Emoji.Emoji (Evergreen.V194.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V194.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V194.Id.Id Evergreen.V194.FileStatus.FileId) Evergreen.V194.FileStatus.FileData
    , embeds : Array.Array Evergreen.V194.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V194.Emoji.Emoji (Evergreen.V194.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
