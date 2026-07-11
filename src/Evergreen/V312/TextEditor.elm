module Evergreen.V312.TextEditor exposing (..)

import Array
import Evergreen.V312.Id
import Evergreen.V312.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V312.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Int
    , history : Array.Array ( Evergreen.V312.Id.Id Evergreen.V312.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) Evergreen.V312.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)
    | Server_Redo (Evergreen.V312.Id.Id Evergreen.V312.Id.UserId)


type alias Model =
    {}
