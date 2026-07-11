module Evergreen.V315.TextEditor exposing (..)

import Array
import Evergreen.V315.Id
import Evergreen.V315.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V315.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Int
    , history : Array.Array ( Evergreen.V315.Id.Id Evergreen.V315.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) Evergreen.V315.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)
    | Server_Redo (Evergreen.V315.Id.Id Evergreen.V315.Id.UserId)


type alias Model =
    {}
