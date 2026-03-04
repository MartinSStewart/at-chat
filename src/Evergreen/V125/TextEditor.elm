module Evergreen.V125.TextEditor exposing (..)

import Array
import Evergreen.V125.Id
import Evergreen.V125.RichText
import SeqDict


type EditChange
    = Edit_TypedText Evergreen.V125.RichText.Range String


type alias LocalState =
    { undoPoint : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Int
    , history : Array.Array ( Evergreen.V125.Id.Id Evergreen.V125.Id.UserId, EditChange )
    , cursorPosition : SeqDict.SeqDict (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.RichText.Range
    }


type LocalChange
    = Local_EditChange EditChange
    | Local_Reset
    | Local_Undo
    | Local_Redo
    | Local_MovedCursor Evergreen.V125.RichText.Range


type ServerChange
    = Server_EditChange (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) EditChange
    | Server_Reset
    | Server_Undo (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | Server_Redo (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId)
    | Server_MovedCursor (Evergreen.V125.Id.Id Evergreen.V125.Id.UserId) Evergreen.V125.RichText.Range


type alias Model =
    {}


type Msg
    = TypedText String
    | MovedCursor Evergreen.V125.RichText.Range
    | PressedReset
    | UndoChange
    | RedoChange
