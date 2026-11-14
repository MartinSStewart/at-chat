module Evergreen.V422.Drawing exposing (..)

import Date
import Evergreen.V422.CssPixels
import Evergreen.V422.FileStatus
import Evergreen.V422.Id
import Evergreen.V422.Point2d
import Evergreen.V422.SafeFloat
import Evergreen.V422.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V422.SafeFloat.SafeFloat, Evergreen.V422.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V422.SafeFloat.SafeFloat, Evergreen.V422.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V422.Id.Id Evergreen.V422.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V422.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V422.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V422.SafeFloat.SafeFloat, Evergreen.V422.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V422.SafeFloat.SafeFloat, Evergreen.V422.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V422.SafeFloat.SafeFloat, Evergreen.V422.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V422.SafeFloat.SafeFloat, Evergreen.V422.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V422.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V422.Point2d.Point2d Evergreen.V422.CssPixels.CssPixels Evergreen.V422.Touch.ScreenCoordinate
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
