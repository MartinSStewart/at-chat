module Evergreen.V351.MessageInput exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V351.Range
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


type Msg
    = PressedTextInput
    | TypedMessage String
    | PressedSendMessage
        { charsLeft : Int
        }
    | PressedArrowInDropdown Int
    | PressedArrowUpInEmptyInput
    | PressedDropdownItem Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | PressedOpenEmojiSelector
    | OnPasteFiles (List.Nonempty.Nonempty Effect.File.File)
    | TypedPageUp
    | TypedPageDown
    | TypedTabInCodeBlock Evergreen.V351.Range.Range
    | IgnoredKeyPress


type alias TextInputFocus =
    { htmlId : Effect.Browser.Dom.HtmlId
    , selection : Evergreen.V351.Range.Range
    , direction : Evergreen.V351.Range.SelectionDirection
    , dropdown : Maybe MentionUserDropdown
    }
