module Evergreen.V392.TextEditor exposing (..)

import Array
import Evergreen.V392.Id
import Evergreen.V392.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V392.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Int
    , history : Array.Array ( Evergreen.V392.Id.Id Evergreen.V392.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) Evergreen.V392.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)
    | Server_Redo (Evergreen.V392.Id.Id Evergreen.V392.Id.UserId)


type alias Model =
    {}
