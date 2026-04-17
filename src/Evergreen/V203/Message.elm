module Evergreen.V203.Message exposing (..)

import Array
import Evergreen.V203.Embed
import Evergreen.V203.Emoji
import Evergreen.V203.FileStatus
import Evergreen.V203.Id
import Evergreen.V203.NonemptySet
import Evergreen.V203.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V203.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V203.Emoji.Emoji (Evergreen.V203.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V203.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V203.Id.Id Evergreen.V203.FileStatus.FileId) Evergreen.V203.FileStatus.FileData
    , embeds : Array.Array Evergreen.V203.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V203.Emoji.Emoji (Evergreen.V203.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
