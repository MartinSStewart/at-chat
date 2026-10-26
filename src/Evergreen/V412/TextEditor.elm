module Evergreen.V412.TextEditor exposing (..)

import Array
import Evergreen.V412.Id
import Evergreen.V412.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V412.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Int
    , history : Array.Array ( Evergreen.V412.Id.Id Evergreen.V412.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) Evergreen.V412.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)
    | Server_Redo (Evergreen.V412.Id.Id Evergreen.V412.Id.UserId)


type alias Model =
    {}
