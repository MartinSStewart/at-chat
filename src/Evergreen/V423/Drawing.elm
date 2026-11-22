module Evergreen.V423.Drawing exposing (..)

import Date
import Evergreen.V423.CssPixels
import Evergreen.V423.FileStatus
import Evergreen.V423.Id
import Evergreen.V423.Point2d
import Evergreen.V423.SafeFloat
import Evergreen.V423.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V423.SafeFloat.SafeFloat, Evergreen.V423.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V423.SafeFloat.SafeFloat, Evergreen.V423.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V423.Id.Id Evergreen.V423.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V423.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V423.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V423.SafeFloat.SafeFloat, Evergreen.V423.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V423.SafeFloat.SafeFloat, Evergreen.V423.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V423.SafeFloat.SafeFloat, Evergreen.V423.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V423.SafeFloat.SafeFloat, Evergreen.V423.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V423.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V423.Point2d.Point2d Evergreen.V423.CssPixels.CssPixels Evergreen.V423.Touch.ScreenCoordinate
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
