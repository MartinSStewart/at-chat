module Evergreen.V267.TextEditor exposing (..)

import Array
import Evergreen.V267.Id
import Evergreen.V267.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V267.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Int
    , history : Array.Array ( Evergreen.V267.Id.Id Evergreen.V267.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) Evergreen.V267.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)
    | Server_Redo (Evergreen.V267.Id.Id Evergreen.V267.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
