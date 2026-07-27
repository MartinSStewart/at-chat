module Evergreen.V336.TextEditor exposing (..)

import Array
import Evergreen.V336.Id
import Evergreen.V336.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V336.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Int
    , history : Array.Array ( Evergreen.V336.Id.Id Evergreen.V336.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) Evergreen.V336.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)
    | Server_Redo (Evergreen.V336.Id.Id Evergreen.V336.Id.UserId)


type alias Model =
    {}
