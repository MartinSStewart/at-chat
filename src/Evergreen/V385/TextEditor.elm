module Evergreen.V385.TextEditor exposing (..)

import Array
import Evergreen.V385.Id
import Evergreen.V385.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V385.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Int
    , history : Array.Array ( Evergreen.V385.Id.Id Evergreen.V385.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) Evergreen.V385.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)
    | Server_Redo (Evergreen.V385.Id.Id Evergreen.V385.Id.UserId)


type alias Model =
    {}
