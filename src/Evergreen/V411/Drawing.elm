module Evergreen.V411.Drawing exposing (..)

import Date
import Evergreen.V411.CssPixels
import Evergreen.V411.FileStatus
import Evergreen.V411.Id
import Evergreen.V411.Point2d
import Evergreen.V411.SafeFloat
import Evergreen.V411.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V411.SafeFloat.SafeFloat, Evergreen.V411.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V411.SafeFloat.SafeFloat, Evergreen.V411.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V411.Id.Id Evergreen.V411.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V411.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V411.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V411.SafeFloat.SafeFloat, Evergreen.V411.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V411.SafeFloat.SafeFloat, Evergreen.V411.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V411.SafeFloat.SafeFloat, Evergreen.V411.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V411.SafeFloat.SafeFloat, Evergreen.V411.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V411.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V411.Point2d.Point2d Evergreen.V411.CssPixels.CssPixels Evergreen.V411.Touch.ScreenCoordinate
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
