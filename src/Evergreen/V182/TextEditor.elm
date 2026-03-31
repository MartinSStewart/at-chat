module Evergreen.V182.TextEditor exposing (..)

import Array
import Evergreen.V182.Id
import Evergreen.V182.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V182.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Int
    , history : Array.Array ( Evergreen.V182.Id.Id Evergreen.V182.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) Evergreen.V182.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)
    | Server_Redo (Evergreen.V182.Id.Id Evergreen.V182.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
