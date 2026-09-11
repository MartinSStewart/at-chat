module Evergreen.V377.TextEditor exposing (..)

import Array
import Evergreen.V377.Id
import Evergreen.V377.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V377.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Int
    , history : Array.Array ( Evergreen.V377.Id.Id Evergreen.V377.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) Evergreen.V377.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)
    | Server_Redo (Evergreen.V377.Id.Id Evergreen.V377.Id.UserId)


type alias Model =
    {}
