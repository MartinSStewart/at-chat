module Evergreen.V330.TextEditor exposing (..)

import Array
import Evergreen.V330.Id
import Evergreen.V330.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V330.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Int
    , history : Array.Array ( Evergreen.V330.Id.Id Evergreen.V330.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) Evergreen.V330.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)
    | Server_Redo (Evergreen.V330.Id.Id Evergreen.V330.Id.UserId)


type alias Model =
    {}
