module Evergreen.V403.TextEditor exposing (..)

import Array
import Evergreen.V403.Id
import Evergreen.V403.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V403.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Int
    , history : Array.Array ( Evergreen.V403.Id.Id Evergreen.V403.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) Evergreen.V403.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)
    | Server_Redo (Evergreen.V403.Id.Id Evergreen.V403.Id.UserId)


type alias Model =
    {}
