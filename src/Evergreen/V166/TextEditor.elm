module Evergreen.V166.TextEditor exposing (..)

import Array
import Evergreen.V166.Id
import Evergreen.V166.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V166.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Int
    , history : Array.Array ( Evergreen.V166.Id.Id Evergreen.V166.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V166.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
    | Server_Redo (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId)
    | Server_MovedCursor (Evergreen.V166.Id.Id Evergreen.V166.Id.UserId) Evergreen.V166.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V166.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
