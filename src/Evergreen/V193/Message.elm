module Evergreen.V193.Message exposing (..)

import Array
import Evergreen.V193.Embed
import Evergreen.V193.Emoji
import Evergreen.V193.FileStatus
import Evergreen.V193.Id
import Evergreen.V193.NonemptySet
import Evergreen.V193.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V193.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V193.Emoji.Emoji (Evergreen.V193.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V193.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V193.Id.Id Evergreen.V193.FileStatus.FileId) Evergreen.V193.FileStatus.FileData
    , embeds : Array.Array Evergreen.V193.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V193.Emoji.Emoji (Evergreen.V193.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
