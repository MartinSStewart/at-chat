module Evergreen.V169.TextEditor exposing (..)

import Array
import Evergreen.V169.Id
import Evergreen.V169.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V169.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Int
    , history : Array.Array ( Evergreen.V169.Id.Id Evergreen.V169.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V169.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
    | Server_Redo (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId)
    | Server_MovedCursor (Evergreen.V169.Id.Id Evergreen.V169.Id.UserId) Evergreen.V169.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V169.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
