module Evergreen.V381.Drawing exposing (..)

import Date
import Evergreen.V381.CssPixels
import Evergreen.V381.FileStatus
import Evergreen.V381.Id
import Evergreen.V381.Point2d
import Evergreen.V381.SafeFloat
import Evergreen.V381.Touch
import List.Nonempty
import SeqDict


type Msg
    = PointerDown Float Float
    | PointerMoved Float Float
    | PointerUp
    | PressedUndo
    | PressedRedo
    | PressedZoom
    | GotZoomContainer
        (Maybe
            { x : Float
            , y : Float
            , width : Float
            , height : Float
            }
        )
    | PressedDone


type alias Stroke =
    { points : List.Nonempty.Nonempty ( Evergreen.V381.SafeFloat.SafeFloat, Evergreen.V381.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V381.SafeFloat.SafeFloat, Evergreen.V381.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V381.Id.Id Evergreen.V381.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V381.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V381.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V381.SafeFloat.SafeFloat, Evergreen.V381.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V381.SafeFloat.SafeFloat, Evergreen.V381.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V381.SafeFloat.SafeFloat, Evergreen.V381.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V381.SafeFloat.SafeFloat, Evergreen.V381.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V381.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V381.Point2d.Point2d Evergreen.V381.CssPixels.CssPixels Evergreen.V381.Touch.ScreenCoordinate
    , pointScale : Float
    , stroke : Maybe ActiveStroke
    , anchorHalfSize : ( Float, Float )
    , zoom : Float
    , zoomContainer :
        Maybe
            { x : Float
            , y : Float
            , width : Float
            , height : Float
            }
    }


type Model
    = NoSelectedAnchor
    | SelectedAnchor SelectedAnchorData
