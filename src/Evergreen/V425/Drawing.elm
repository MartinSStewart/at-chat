module Evergreen.V425.Drawing exposing (..)

import Date
import Evergreen.V425.CssPixels
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import Evergreen.V425.Point2d
import Evergreen.V425.SafeFloat
import Evergreen.V425.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V425.SafeFloat.SafeFloat, Evergreen.V425.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V425.SafeFloat.SafeFloat, Evergreen.V425.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V425.Id.Id Evergreen.V425.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V425.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V425.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V425.SafeFloat.SafeFloat, Evergreen.V425.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V425.SafeFloat.SafeFloat, Evergreen.V425.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V425.SafeFloat.SafeFloat, Evergreen.V425.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V425.SafeFloat.SafeFloat, Evergreen.V425.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V425.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V425.Point2d.Point2d Evergreen.V425.CssPixels.CssPixels Evergreen.V425.Touch.ScreenCoordinate
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
