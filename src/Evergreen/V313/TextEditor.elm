module Evergreen.V313.TextEditor exposing (..)

import Array
import Evergreen.V313.Id
import Evergreen.V313.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V313.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Int
    , history : Array.Array ( Evergreen.V313.Id.Id Evergreen.V313.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) Evergreen.V313.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)
    | Server_Redo (Evergreen.V313.Id.Id Evergreen.V313.Id.UserId)


type alias Model =
    {}
