module Evergreen.V382.Drawing exposing (..)

import Date
import Evergreen.V382.CssPixels
import Evergreen.V382.FileStatus
import Evergreen.V382.Id
import Evergreen.V382.Point2d
import Evergreen.V382.SafeFloat
import Evergreen.V382.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V382.SafeFloat.SafeFloat, Evergreen.V382.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V382.SafeFloat.SafeFloat, Evergreen.V382.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V382.Id.Id Evergreen.V382.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V382.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V382.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V382.SafeFloat.SafeFloat, Evergreen.V382.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V382.SafeFloat.SafeFloat, Evergreen.V382.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V382.SafeFloat.SafeFloat, Evergreen.V382.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V382.SafeFloat.SafeFloat, Evergreen.V382.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V382.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V382.Point2d.Point2d Evergreen.V382.CssPixels.CssPixels Evergreen.V382.Touch.ScreenCoordinate
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
