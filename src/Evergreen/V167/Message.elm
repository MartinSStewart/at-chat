module Evergreen.V167.Message exposing (..)

import Array
import Evergreen.V167.Embed
import Evergreen.V167.Emoji
import Evergreen.V167.FileStatus
import Evergreen.V167.Id
import Evergreen.V167.NonemptySet
import Evergreen.V167.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V167.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V167.Emoji.Emoji (Evergreen.V167.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V167.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.FileStatus.FileId) Evergreen.V167.FileStatus.FileData
    , embeds : Array.Array Evergreen.V167.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V167.Emoji.Emoji (Evergreen.V167.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
