module Evergreen.V251.TextEditor exposing (..)

import Array
import Evergreen.V251.Id
import Evergreen.V251.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V251.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Int
    , history : Array.Array ( Evergreen.V251.Id.Id Evergreen.V251.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) Evergreen.V251.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)
    | Server_Redo (Evergreen.V251.Id.Id Evergreen.V251.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
