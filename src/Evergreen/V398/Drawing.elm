module Evergreen.V398.Drawing exposing (..)

import Date
import Evergreen.V398.CssPixels
import Evergreen.V398.FileStatus
import Evergreen.V398.Id
import Evergreen.V398.Point2d
import Evergreen.V398.SafeFloat
import Evergreen.V398.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V398.SafeFloat.SafeFloat, Evergreen.V398.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V398.SafeFloat.SafeFloat, Evergreen.V398.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V398.Id.Id Evergreen.V398.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V398.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V398.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V398.SafeFloat.SafeFloat, Evergreen.V398.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V398.SafeFloat.SafeFloat, Evergreen.V398.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V398.SafeFloat.SafeFloat, Evergreen.V398.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V398.SafeFloat.SafeFloat, Evergreen.V398.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V398.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V398.Point2d.Point2d Evergreen.V398.CssPixels.CssPixels Evergreen.V398.Touch.ScreenCoordinate
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
