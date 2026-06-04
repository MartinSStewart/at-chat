module Evergreen.V275.TextEditor exposing (..)

import Array
import Evergreen.V275.Id
import Evergreen.V275.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V275.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Int
    , history : Array.Array ( Evergreen.V275.Id.Id Evergreen.V275.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) Evergreen.V275.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)
    | Server_Redo (Evergreen.V275.Id.Id Evergreen.V275.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
