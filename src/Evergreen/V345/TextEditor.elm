module Evergreen.V345.TextEditor exposing (..)

import Array
import Evergreen.V345.Id
import Evergreen.V345.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V345.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Int
    , history : Array.Array ( Evergreen.V345.Id.Id Evergreen.V345.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) Evergreen.V345.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)
    | Server_Redo (Evergreen.V345.Id.Id Evergreen.V345.Id.UserId)


type alias Model =
    {}
