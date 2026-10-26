module Evergreen.V413.Drawing exposing (..)

import Date
import Evergreen.V413.CssPixels
import Evergreen.V413.FileStatus
import Evergreen.V413.Id
import Evergreen.V413.Point2d
import Evergreen.V413.SafeFloat
import Evergreen.V413.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V413.SafeFloat.SafeFloat, Evergreen.V413.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V413.SafeFloat.SafeFloat, Evergreen.V413.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V413.Id.Id Evergreen.V413.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V413.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V413.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V413.SafeFloat.SafeFloat, Evergreen.V413.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V413.SafeFloat.SafeFloat, Evergreen.V413.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V413.SafeFloat.SafeFloat, Evergreen.V413.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V413.SafeFloat.SafeFloat, Evergreen.V413.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V413.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V413.Point2d.Point2d Evergreen.V413.CssPixels.CssPixels Evergreen.V413.Touch.ScreenCoordinate
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
