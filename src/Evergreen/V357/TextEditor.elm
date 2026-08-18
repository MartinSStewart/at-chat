module Evergreen.V357.TextEditor exposing (..)

import Array
import Evergreen.V357.Id
import Evergreen.V357.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V357.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Int
    , history : Array.Array ( Evergreen.V357.Id.Id Evergreen.V357.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) Evergreen.V357.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)
    | Server_Redo (Evergreen.V357.Id.Id Evergreen.V357.Id.UserId)


type alias Model =
    {}
