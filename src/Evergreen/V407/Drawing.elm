module Evergreen.V407.Drawing exposing (..)

import Date
import Evergreen.V407.CssPixels
import Evergreen.V407.FileStatus
import Evergreen.V407.Id
import Evergreen.V407.Point2d
import Evergreen.V407.SafeFloat
import Evergreen.V407.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V407.SafeFloat.SafeFloat, Evergreen.V407.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V407.SafeFloat.SafeFloat, Evergreen.V407.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V407.Id.Id Evergreen.V407.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V407.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V407.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V407.SafeFloat.SafeFloat, Evergreen.V407.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V407.SafeFloat.SafeFloat, Evergreen.V407.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V407.SafeFloat.SafeFloat, Evergreen.V407.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V407.SafeFloat.SafeFloat, Evergreen.V407.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V407.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V407.Point2d.Point2d Evergreen.V407.CssPixels.CssPixels Evergreen.V407.Touch.ScreenCoordinate
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
