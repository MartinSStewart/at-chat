module Evergreen.V211.TextEditor exposing (..)

import Array
import Evergreen.V211.Id
import Evergreen.V211.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V211.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Int
    , history : Array.Array ( Evergreen.V211.Id.Id Evergreen.V211.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) Evergreen.V211.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)
    | Server_Redo (Evergreen.V211.Id.Id Evergreen.V211.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
