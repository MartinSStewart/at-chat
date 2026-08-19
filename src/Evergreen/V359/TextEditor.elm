module Evergreen.V359.TextEditor exposing (..)

import Array
import Evergreen.V359.Id
import Evergreen.V359.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V359.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Int
    , history : Array.Array ( Evergreen.V359.Id.Id Evergreen.V359.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) Evergreen.V359.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)
    | Server_Redo (Evergreen.V359.Id.Id Evergreen.V359.Id.UserId)


type alias Model =
    {}
