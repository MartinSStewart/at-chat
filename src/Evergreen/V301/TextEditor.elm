module Evergreen.V301.TextEditor exposing (..)

import Array
import Evergreen.V301.Id
import Evergreen.V301.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V301.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Int
    , history : Array.Array ( Evergreen.V301.Id.Id Evergreen.V301.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) Evergreen.V301.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)
    | Server_Redo (Evergreen.V301.Id.Id Evergreen.V301.Id.UserId)


type alias Model =
    {}
