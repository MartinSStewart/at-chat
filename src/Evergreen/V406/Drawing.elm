module Evergreen.V406.Drawing exposing (..)

import Date
import Evergreen.V406.CssPixels
import Evergreen.V406.FileStatus
import Evergreen.V406.Id
import Evergreen.V406.Point2d
import Evergreen.V406.SafeFloat
import Evergreen.V406.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V406.SafeFloat.SafeFloat, Evergreen.V406.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V406.SafeFloat.SafeFloat, Evergreen.V406.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V406.Id.Id Evergreen.V406.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V406.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V406.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V406.SafeFloat.SafeFloat, Evergreen.V406.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V406.SafeFloat.SafeFloat, Evergreen.V406.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V406.SafeFloat.SafeFloat, Evergreen.V406.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V406.SafeFloat.SafeFloat, Evergreen.V406.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V406.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V406.Point2d.Point2d Evergreen.V406.CssPixels.CssPixels Evergreen.V406.Touch.ScreenCoordinate
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
