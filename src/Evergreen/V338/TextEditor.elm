module Evergreen.V338.TextEditor exposing (..)

import Array
import Evergreen.V338.Id
import Evergreen.V338.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V338.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Int
    , history : Array.Array ( Evergreen.V338.Id.Id Evergreen.V338.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) Evergreen.V338.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)
    | Server_Redo (Evergreen.V338.Id.Id Evergreen.V338.Id.UserId)


type alias Model =
    {}
