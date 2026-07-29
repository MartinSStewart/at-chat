module Evergreen.V339.TextEditor exposing (..)

import Array
import Evergreen.V339.Id
import Evergreen.V339.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V339.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Int
    , history : Array.Array ( Evergreen.V339.Id.Id Evergreen.V339.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) Evergreen.V339.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)
    | Server_Redo (Evergreen.V339.Id.Id Evergreen.V339.Id.UserId)


type alias Model =
    {}
