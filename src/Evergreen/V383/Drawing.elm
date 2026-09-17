module Evergreen.V383.Drawing exposing (..)

import Date
import Evergreen.V383.CssPixels
import Evergreen.V383.FileStatus
import Evergreen.V383.Id
import Evergreen.V383.Point2d
import Evergreen.V383.SafeFloat
import Evergreen.V383.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V383.SafeFloat.SafeFloat, Evergreen.V383.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V383.SafeFloat.SafeFloat, Evergreen.V383.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V383.Id.Id Evergreen.V383.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V383.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V383.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V383.SafeFloat.SafeFloat, Evergreen.V383.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V383.SafeFloat.SafeFloat, Evergreen.V383.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V383.SafeFloat.SafeFloat, Evergreen.V383.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V383.SafeFloat.SafeFloat, Evergreen.V383.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V383.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V383.Point2d.Point2d Evergreen.V383.CssPixels.CssPixels Evergreen.V383.Touch.ScreenCoordinate
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
