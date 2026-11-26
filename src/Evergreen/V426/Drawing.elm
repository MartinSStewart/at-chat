module Evergreen.V426.Drawing exposing (..)

import Date
import Evergreen.V426.CssPixels
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import Evergreen.V426.Point2d
import Evergreen.V426.SafeFloat
import Evergreen.V426.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V426.SafeFloat.SafeFloat, Evergreen.V426.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V426.SafeFloat.SafeFloat, Evergreen.V426.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V426.Id.Id Evergreen.V426.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V426.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V426.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V426.SafeFloat.SafeFloat, Evergreen.V426.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V426.SafeFloat.SafeFloat, Evergreen.V426.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V426.SafeFloat.SafeFloat, Evergreen.V426.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V426.SafeFloat.SafeFloat, Evergreen.V426.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V426.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V426.Point2d.Point2d Evergreen.V426.CssPixels.CssPixels Evergreen.V426.Touch.ScreenCoordinate
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
