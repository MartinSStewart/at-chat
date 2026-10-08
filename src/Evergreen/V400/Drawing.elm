module Evergreen.V400.Drawing exposing (..)

import Date
import Evergreen.V400.CssPixels
import Evergreen.V400.FileStatus
import Evergreen.V400.Id
import Evergreen.V400.Point2d
import Evergreen.V400.SafeFloat
import Evergreen.V400.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V400.SafeFloat.SafeFloat, Evergreen.V400.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V400.SafeFloat.SafeFloat, Evergreen.V400.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V400.Id.Id Evergreen.V400.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V400.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V400.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V400.SafeFloat.SafeFloat, Evergreen.V400.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V400.SafeFloat.SafeFloat, Evergreen.V400.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V400.SafeFloat.SafeFloat, Evergreen.V400.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V400.SafeFloat.SafeFloat, Evergreen.V400.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V400.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V400.Point2d.Point2d Evergreen.V400.CssPixels.CssPixels Evergreen.V400.Touch.ScreenCoordinate
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
