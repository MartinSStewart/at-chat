module Evergreen.V423.TextEditor exposing (..)

import Array
import Evergreen.V423.Id
import Evergreen.V423.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V423.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Int
    , history : Array.Array ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) Evergreen.V423.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)
    | Server_Redo (Evergreen.V423.Id.Id Evergreen.V423.Id.UserId)


type alias Model =
    {}
