module Evergreen.V171.Message exposing (..)

import Array
import Evergreen.V171.Embed
import Evergreen.V171.Emoji
import Evergreen.V171.FileStatus
import Evergreen.V171.Id
import Evergreen.V171.NonemptySet
import Evergreen.V171.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V171.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V171.Emoji.Emoji (Evergreen.V171.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V171.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V171.Id.Id Evergreen.V171.FileStatus.FileId) Evergreen.V171.FileStatus.FileData
    , embeds : Array.Array Evergreen.V171.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V171.Emoji.Emoji (Evergreen.V171.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
