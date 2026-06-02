module Evergreen.V264.TextEditor exposing (..)

import Array
import Evergreen.V264.Id
import Evergreen.V264.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V264.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Int
    , history : Array.Array ( Evergreen.V264.Id.Id Evergreen.V264.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) Evergreen.V264.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)
    | Server_Redo (Evergreen.V264.Id.Id Evergreen.V264.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
