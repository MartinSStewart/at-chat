module Evergreen.V360.TextEditor exposing (..)

import Array
import Evergreen.V360.Id
import Evergreen.V360.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V360.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Int
    , history : Array.Array ( Evergreen.V360.Id.Id Evergreen.V360.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) Evergreen.V360.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)
    | Server_Redo (Evergreen.V360.Id.Id Evergreen.V360.Id.UserId)


type alias Model =
    {}
