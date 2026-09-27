module Evergreen.V386.Drawing exposing (..)

import Date
import Evergreen.V386.CssPixels
import Evergreen.V386.FileStatus
import Evergreen.V386.Id
import Evergreen.V386.Point2d
import Evergreen.V386.SafeFloat
import Evergreen.V386.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V386.SafeFloat.SafeFloat, Evergreen.V386.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V386.SafeFloat.SafeFloat, Evergreen.V386.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V386.Id.Id Evergreen.V386.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V386.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V386.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V386.SafeFloat.SafeFloat, Evergreen.V386.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V386.SafeFloat.SafeFloat, Evergreen.V386.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V386.SafeFloat.SafeFloat, Evergreen.V386.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V386.SafeFloat.SafeFloat, Evergreen.V386.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V386.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V386.Point2d.Point2d Evergreen.V386.CssPixels.CssPixels Evergreen.V386.Touch.ScreenCoordinate
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
