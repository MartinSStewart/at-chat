module Evergreen.V187.TextEditor exposing (..)

import Array
import Evergreen.V187.Id
import Evergreen.V187.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V187.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Int
    , history : Array.Array ( Evergreen.V187.Id.Id Evergreen.V187.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) Evergreen.V187.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)
    | Server_Redo (Evergreen.V187.Id.Id Evergreen.V187.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
