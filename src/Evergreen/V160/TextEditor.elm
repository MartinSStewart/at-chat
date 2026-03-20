module Evergreen.V160.TextEditor exposing (..)

import Array
import Evergreen.V160.Id
import Evergreen.V160.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V160.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Int
    , history : Array.Array ( Evergreen.V160.Id.Id Evergreen.V160.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V160.MyUi.Range


type ServerChange
    = Server_EditChange (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    | Server_Redo (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId)
    | Server_MovedCursor (Evergreen.V160.Id.Id Evergreen.V160.Id.UserId) Evergreen.V160.MyUi.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V160.MyUi.Range
    | PressedReset
    | UndoChange
    | RedoChange
