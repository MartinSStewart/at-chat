module Evergreen.V368.MessageInput exposing (..)

import Effect.Browser.Dom
import Effect.File
import Evergreen.V368.Range
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
    | TypedArrowInDropdown Int
    | TypedArrowUpInEmptyInput
    | PressedDropdownItem Int
    | PressedPingDropdownContainer
    | PressedUploadFile
    | PressedOpenEmojiSelector
    | OnPasteFiles (List.Nonempty.Nonempty Effect.File.File)
    | TypedPageUp
    | TypedPageDown
    | TypedTabInCodeBlock Evergreen.V368.Range.Range
    | IgnoredKeyPress


type alias TextInputFocus =
    { htmlId : Effect.Browser.Dom.HtmlId
    , selection : Evergreen.V368.Range.Range
    , direction : Evergreen.V368.Range.SelectionDirection
    , dropdown : Maybe MentionUserDropdown
    }
