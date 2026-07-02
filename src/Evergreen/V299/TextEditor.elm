module Evergreen.V299.TextEditor exposing (..)

import Array
import Evergreen.V299.Id
import Evergreen.V299.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V299.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Int
    , history : Array.Array ( Evergreen.V299.Id.Id Evergreen.V299.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) Evergreen.V299.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)
    | Server_Redo (Evergreen.V299.Id.Id Evergreen.V299.Id.UserId)


type alias Model =
    {}
