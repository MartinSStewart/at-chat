module Evergreen.V311.TextEditor exposing (..)

import Array
import Evergreen.V311.Id
import Evergreen.V311.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V311.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Int
    , history : Array.Array ( Evergreen.V311.Id.Id Evergreen.V311.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) Evergreen.V311.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)
    | Server_Redo (Evergreen.V311.Id.Id Evergreen.V311.Id.UserId)


type alias Model =
    {}
