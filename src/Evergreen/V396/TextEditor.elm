module Evergreen.V396.TextEditor exposing (..)

import Array
import Evergreen.V396.Id
import Evergreen.V396.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V396.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Int
    , history : Array.Array ( Evergreen.V396.Id.Id Evergreen.V396.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) Evergreen.V396.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)
    | Server_Redo (Evergreen.V396.Id.Id Evergreen.V396.Id.UserId)


type alias Model =
    {}
