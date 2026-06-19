module Evergreen.V290.TextEditor exposing (..)

import Array
import Evergreen.V290.Id
import Evergreen.V290.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V290.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Int
    , history : Array.Array ( Evergreen.V290.Id.Id Evergreen.V290.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) Evergreen.V290.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)
    | Server_Redo (Evergreen.V290.Id.Id Evergreen.V290.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack
