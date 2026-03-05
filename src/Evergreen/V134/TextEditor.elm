module Evergreen.V134.TextEditor exposing (..)

import Array
import Evergreen.V134.Id
import Evergreen.V134.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V134.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Int
    , history : Array.Array ( Evergreen.V134.Id.Id Evergreen.V134.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V134.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    | Server_Redo (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId)
    | Server_MovedCursor (Evergreen.V134.Id.Id Evergreen.V134.Id.UserId) Evergreen.V134.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V134.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
