module Evergreen.V409.Drawing exposing (..)

import Date
import Evergreen.V409.CssPixels
import Evergreen.V409.FileStatus
import Evergreen.V409.Id
import Evergreen.V409.Point2d
import Evergreen.V409.SafeFloat
import Evergreen.V409.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V409.SafeFloat.SafeFloat, Evergreen.V409.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V409.SafeFloat.SafeFloat, Evergreen.V409.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V409.Id.Id Evergreen.V409.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V409.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V409.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V409.SafeFloat.SafeFloat, Evergreen.V409.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V409.SafeFloat.SafeFloat, Evergreen.V409.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V409.SafeFloat.SafeFloat, Evergreen.V409.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V409.SafeFloat.SafeFloat, Evergreen.V409.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V409.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V409.Point2d.Point2d Evergreen.V409.CssPixels.CssPixels Evergreen.V409.Touch.ScreenCoordinate
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
