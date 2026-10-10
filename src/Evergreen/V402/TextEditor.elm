module Evergreen.V402.TextEditor exposing (..)

import Array
import Evergreen.V402.Id
import Evergreen.V402.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V402.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Int
    , history : Array.Array ( Evergreen.V402.Id.Id Evergreen.V402.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) Evergreen.V402.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)
    | Server_Redo (Evergreen.V402.Id.Id Evergreen.V402.Id.UserId)


type alias Model =
    {}
