module Evergreen.V206.MessageInput exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V206.Range
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
    , selection : Evergreen.V206.Range.Range
    , direction : Evergreen.V206.Range.SelectionDirection
    , dropdown : Maybe MentionUserDropdown
    }


type Msg
    = PressedTextInput
    | TypedMessage String
    | PressedSendMessage
    | PressedArrowInDropdown Int
    | PressedArrowUpInEmptyInput
    | PressedDropdownItem Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | PressedOpenEmojiSelector
    | OnPasteFiles (List.Nonempty.Nonempty Effect.File.File)
