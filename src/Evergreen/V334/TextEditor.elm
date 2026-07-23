module Evergreen.V334.TextEditor exposing (..)

import Array
import Evergreen.V334.Id
import Evergreen.V334.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V334.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Int
    , history : Array.Array ( Evergreen.V334.Id.Id Evergreen.V334.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) Evergreen.V334.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)
    | Server_Redo (Evergreen.V334.Id.Id Evergreen.V334.Id.UserId)


type alias Model =
    {}
