module Evergreen.V347.TextEditor exposing (..)

import Array
import Evergreen.V347.Id
import Evergreen.V347.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V347.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Int
    , history : Array.Array ( Evergreen.V347.Id.Id Evergreen.V347.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) Evergreen.V347.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)
    | Server_Redo (Evergreen.V347.Id.Id Evergreen.V347.Id.UserId)


type alias Model =
    {}
