module Evergreen.V316.TextEditor exposing (..)

import Array
import Evergreen.V316.Id
import Evergreen.V316.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V316.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Int
    , history : Array.Array ( Evergreen.V316.Id.Id Evergreen.V316.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) Evergreen.V316.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)
    | Server_Redo (Evergreen.V316.Id.Id Evergreen.V316.Id.UserId)


type alias Model =
    {}
