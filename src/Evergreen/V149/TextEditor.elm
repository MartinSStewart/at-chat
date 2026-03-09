module Evergreen.V149.TextEditor exposing (..)

import Array
import Evergreen.V149.Id
import Evergreen.V149.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V149.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Int
    , history : Array.Array ( Evergreen.V149.Id.Id Evergreen.V149.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V149.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    | Server_Redo (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId)
    | Server_MovedCursor (Evergreen.V149.Id.Id Evergreen.V149.Id.UserId) Evergreen.V149.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V149.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
