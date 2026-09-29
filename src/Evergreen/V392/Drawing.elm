module Evergreen.V392.Drawing exposing (..)

import Date
import Evergreen.V392.CssPixels
import Evergreen.V392.FileStatus
import Evergreen.V392.Id
import Evergreen.V392.Point2d
import Evergreen.V392.SafeFloat
import Evergreen.V392.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V392.SafeFloat.SafeFloat, Evergreen.V392.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V392.SafeFloat.SafeFloat, Evergreen.V392.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V392.Id.Id Evergreen.V392.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V392.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V392.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V392.SafeFloat.SafeFloat, Evergreen.V392.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V392.SafeFloat.SafeFloat, Evergreen.V392.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V392.SafeFloat.SafeFloat, Evergreen.V392.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V392.SafeFloat.SafeFloat, Evergreen.V392.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V392.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V392.Point2d.Point2d Evergreen.V392.CssPixels.CssPixels Evergreen.V392.Touch.ScreenCoordinate
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
