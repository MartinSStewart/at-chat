module Evergreen.V305.TextEditor exposing (..)

import Array
import Evergreen.V305.Id
import Evergreen.V305.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V305.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Int
    , history : Array.Array ( Evergreen.V305.Id.Id Evergreen.V305.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) Evergreen.V305.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)
    | Server_Redo (Evergreen.V305.Id.Id Evergreen.V305.Id.UserId)


type alias Model =
    {}
