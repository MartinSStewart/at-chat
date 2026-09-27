module Evergreen.V386.TextEditor exposing (..)

import Array
import Evergreen.V386.Id
import Evergreen.V386.Range
import SeqDict


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
    | PressedBack


type EditChange
    = Edit_TypedText Evergreen.V386.Range.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Int
    , history : Array.Array ( Evergreen.V386.Id.Id Evergreen.V386.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) Evergreen.V386.Range.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)
    | Server_Redo (Evergreen.V386.Id.Id Evergreen.V386.Id.UserId)


type alias Model =
    {}
