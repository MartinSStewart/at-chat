module Evergreen.V379.Drawing exposing (..)

import Date
import Evergreen.V379.CssPixels
import Evergreen.V379.FileStatus
import Evergreen.V379.Id
import Evergreen.V379.Point2d
import Evergreen.V379.SafeFloat
import Evergreen.V379.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V379.SafeFloat.SafeFloat, Evergreen.V379.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V379.SafeFloat.SafeFloat, Evergreen.V379.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V379.Id.Id Evergreen.V379.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V379.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V379.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V379.SafeFloat.SafeFloat, Evergreen.V379.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V379.SafeFloat.SafeFloat, Evergreen.V379.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V379.SafeFloat.SafeFloat, Evergreen.V379.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V379.SafeFloat.SafeFloat, Evergreen.V379.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V379.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V379.Point2d.Point2d Evergreen.V379.CssPixels.CssPixels Evergreen.V379.Touch.ScreenCoordinate
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
