module Evergreen.V412.Drawing exposing (..)

import Date
import Evergreen.V412.CssPixels
import Evergreen.V412.FileStatus
import Evergreen.V412.Id
import Evergreen.V412.Point2d
import Evergreen.V412.SafeFloat
import Evergreen.V412.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V412.SafeFloat.SafeFloat, Evergreen.V412.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V412.SafeFloat.SafeFloat, Evergreen.V412.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V412.Id.Id Evergreen.V412.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V412.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V412.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V412.SafeFloat.SafeFloat, Evergreen.V412.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V412.SafeFloat.SafeFloat, Evergreen.V412.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V412.SafeFloat.SafeFloat, Evergreen.V412.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V412.SafeFloat.SafeFloat, Evergreen.V412.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V412.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V412.Point2d.Point2d Evergreen.V412.CssPixels.CssPixels Evergreen.V412.Touch.ScreenCoordinate
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
