module Evergreen.V332.TextEditor exposing (..)

import Array
import Evergreen.V332.Id
import Evergreen.V332.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V332.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Int
    , history : Array.Array ( Evergreen.V332.Id.Id Evergreen.V332.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) Evergreen.V332.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)
    | Server_Redo (Evergreen.V332.Id.Id Evergreen.V332.Id.UserId)


type alias Model =
    {}
