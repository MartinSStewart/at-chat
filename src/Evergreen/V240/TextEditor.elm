module Evergreen.V240.TextEditor exposing (..)

import Array
import Evergreen.V240.Id
import Evergreen.V240.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V240.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Int
    , history : Array.Array ( Evergreen.V240.Id.Id Evergreen.V240.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) Evergreen.V240.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)
    | Server_Redo (Evergreen.V240.Id.Id Evergreen.V240.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
