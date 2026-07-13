module Evergreen.V317.TextEditor exposing (..)

import Array
import Evergreen.V317.Id
import Evergreen.V317.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V317.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Int
    , history : Array.Array ( Evergreen.V317.Id.Id Evergreen.V317.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) Evergreen.V317.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)
    | Server_Redo (Evergreen.V317.Id.Id Evergreen.V317.Id.UserId)


type alias Model =
    {}
