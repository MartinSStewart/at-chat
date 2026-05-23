module Evergreen.V247.TextEditor exposing (..)

import Array
import Evergreen.V247.Id
import Evergreen.V247.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V247.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Int
    , history : Array.Array ( Evergreen.V247.Id.Id Evergreen.V247.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) Evergreen.V247.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)
    | Server_Redo (Evergreen.V247.Id.Id Evergreen.V247.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
