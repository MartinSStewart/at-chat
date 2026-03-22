module Evergreen.V167.TextEditor exposing (..)

import Array
import Evergreen.V167.Id
import Evergreen.V167.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V167.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Int
    , history : Array.Array ( Evergreen.V167.Id.Id Evergreen.V167.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V167.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
    | Server_Redo (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId)
    | Server_MovedCursor (Evergreen.V167.Id.Id Evergreen.V167.Id.UserId) Evergreen.V167.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V167.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
