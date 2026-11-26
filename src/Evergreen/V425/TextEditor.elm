module Evergreen.V425.TextEditor exposing (..)

import Array
import Evergreen.V425.Id
import Evergreen.V425.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V425.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Int
    , history : Array.Array ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) Evergreen.V425.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)
    | Server_Redo (Evergreen.V425.Id.Id Evergreen.V425.Id.UserId)


type alias Model =
    {}
