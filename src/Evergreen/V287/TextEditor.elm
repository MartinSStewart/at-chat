module Evergreen.V287.TextEditor exposing (..)

import Array
import Evergreen.V287.Id
import Evergreen.V287.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V287.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Int
    , history : Array.Array ( Evergreen.V287.Id.Id Evergreen.V287.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) Evergreen.V287.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)
    | Server_Redo (Evergreen.V287.Id.Id Evergreen.V287.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
