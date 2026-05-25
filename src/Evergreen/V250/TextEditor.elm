module Evergreen.V250.TextEditor exposing (..)

import Array
import Evergreen.V250.Id
import Evergreen.V250.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V250.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Int
    , history : Array.Array ( Evergreen.V250.Id.Id Evergreen.V250.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) Evergreen.V250.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)
    | Server_Redo (Evergreen.V250.Id.Id Evergreen.V250.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
