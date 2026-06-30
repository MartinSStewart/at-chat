module Evergreen.V297.TextEditor exposing (..)

import Array
import Evergreen.V297.Id
import Evergreen.V297.Range
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V297.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Int
    , history : Array.Array ( Evergreen.V297.Id.Id Evergreen.V297.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) Evergreen.V297.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)
    | Server_Redo (Evergreen.V297.Id.Id Evergreen.V297.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack
