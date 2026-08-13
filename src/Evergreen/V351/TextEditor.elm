module Evergreen.V351.TextEditor exposing (..)

import Array
import Evergreen.V351.Id
import Evergreen.V351.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V351.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Int
    , history : Array.Array ( Evergreen.V351.Id.Id Evergreen.V351.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) Evergreen.V351.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)
    | Server_Redo (Evergreen.V351.Id.Id Evergreen.V351.Id.UserId)


type alias Model =
    {}
