module Evergreen.V186.TextEditor exposing (..)

import Array
import Evergreen.V186.Id
import Evergreen.V186.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V186.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Int
    , history : Array.Array ( Evergreen.V186.Id.Id Evergreen.V186.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) Evergreen.V186.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)
    | Server_Redo (Evergreen.V186.Id.Id Evergreen.V186.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
