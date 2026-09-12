module Evergreen.V379.TextEditor exposing (..)

import Array
import Evergreen.V379.Id
import Evergreen.V379.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V379.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Int
    , history : Array.Array ( Evergreen.V379.Id.Id Evergreen.V379.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) Evergreen.V379.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)
    | Server_Redo (Evergreen.V379.Id.Id Evergreen.V379.Id.UserId)


type alias Model =
    {}
