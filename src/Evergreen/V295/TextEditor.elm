module Evergreen.V295.TextEditor exposing (..)

import Array
import Evergreen.V295.Id
import Evergreen.V295.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V295.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Int
    , history : Array.Array ( Evergreen.V295.Id.Id Evergreen.V295.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) Evergreen.V295.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)
    | Server_Redo (Evergreen.V295.Id.Id Evergreen.V295.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack
