module Evergreen.V402.Drawing exposing (..)

import Date
import Evergreen.V402.CssPixels
import Evergreen.V402.FileStatus
import Evergreen.V402.Id
import Evergreen.V402.Point2d
import Evergreen.V402.SafeFloat
import Evergreen.V402.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V402.SafeFloat.SafeFloat, Evergreen.V402.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V402.SafeFloat.SafeFloat, Evergreen.V402.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V402.Id.Id Evergreen.V402.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V402.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V402.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V402.SafeFloat.SafeFloat, Evergreen.V402.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V402.SafeFloat.SafeFloat, Evergreen.V402.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V402.SafeFloat.SafeFloat, Evergreen.V402.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V402.SafeFloat.SafeFloat, Evergreen.V402.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V402.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V402.Point2d.Point2d Evergreen.V402.CssPixels.CssPixels Evergreen.V402.Touch.ScreenCoordinate
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
