module Evergreen.V366.TextEditor exposing (..)

import Array
import Evergreen.V366.Id
import Evergreen.V366.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V366.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Int
    , history : Array.Array ( Evergreen.V366.Id.Id Evergreen.V366.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) Evergreen.V366.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)
    | Server_Redo (Evergreen.V366.Id.Id Evergreen.V366.Id.UserId)


type alias Model =
    {}
