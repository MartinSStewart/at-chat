module Evergreen.V348.TextEditor exposing (..)

import Array
import Evergreen.V348.Id
import Evergreen.V348.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V348.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Int
    , history : Array.Array ( Evergreen.V348.Id.Id Evergreen.V348.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) Evergreen.V348.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)
    | Server_Redo (Evergreen.V348.Id.Id Evergreen.V348.Id.UserId)


type alias Model =
    {}
