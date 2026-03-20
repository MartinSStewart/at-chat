module Evergreen.V161.MessageInput exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V161.MyUi
import List.Nonempty


type alias MentionUserDropdown =
    { dropdownIndex : Int
    , inputElement :
        { x : Float
        , y : Float
        , width : Float
        , height : Float
        }
    }


type alias TextInputFocus =
    { htmlId : Effect.Browser.Dom.HtmlId
    , selection : Evergreen.V161.MyUi.Range
    , dropdown : Maybe MentionUserDropdown
    }


type Msg
    = TextInputGotFocus Effect.Browser.Dom.HtmlId
    | TextInputLostFocus Effect.Browser.Dom.HtmlId
    | PressedTextInput
    | TypedMessage String
    | PressedSendMessage
    | PressedArrowInDropdown Int
    | PressedArrowUpInEmptyInput
    | PressedPingUser Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | OnPasteFiles (List.Nonempty.Nonempty Effect.File.File)
    | OnSelectionChanged Effect.Browser.Dom.HtmlId Evergreen.V161.MyUi.Range
