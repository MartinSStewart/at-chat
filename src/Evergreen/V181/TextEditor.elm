module Evergreen.V181.TextEditor exposing (..)

import Array
import Evergreen.V181.Id
import Evergreen.V181.MyUi
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V181.MyUi.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Int
    , history : Array.Array ( Evergreen.V181.Id.Id Evergreen.V181.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) Evergreen.V181.MyUi.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo


type ServerChange
    = Server_EditChange (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)
    | Server_Redo (Evergreen.V181.Id.Id Evergreen.V181.Id.UserId)


type alias Model =
    {}


type Msg
    = TypedText String
    | PressedReset
    | UndoChange
    | RedoChange
