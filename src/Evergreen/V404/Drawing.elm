module Evergreen.V404.Drawing exposing (..)

import Date
import Evergreen.V404.CssPixels
import Evergreen.V404.FileStatus
import Evergreen.V404.Id
import Evergreen.V404.Point2d
import Evergreen.V404.SafeFloat
import Evergreen.V404.Touch
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
    { points : List.Nonempty.Nonempty ( Evergreen.V404.SafeFloat.SafeFloat, Evergreen.V404.SafeFloat.SafeFloat )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Evergreen.V404.SafeFloat.SafeFloat, Evergreen.V404.SafeFloat.SafeFloat )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V404.Id.Id Evergreen.V404.FileStatus.FileId)
    | EmbedImageAnchor Int
    | CardAnchor


type AnchorType
    = MessageAnchor Evergreen.V404.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V404.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Evergreen.V404.SafeFloat.SafeFloat, Evergreen.V404.SafeFloat.SafeFloat )
    | ContinueStroke (List.Nonempty.Nonempty ( Evergreen.V404.SafeFloat.SafeFloat, Evergreen.V404.SafeFloat.SafeFloat ))
    | EndStroke (List ( Evergreen.V404.SafeFloat.SafeFloat, Evergreen.V404.SafeFloat.SafeFloat ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Evergreen.V404.SafeFloat.SafeFloat, Evergreen.V404.SafeFloat.SafeFloat )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V404.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V404.Point2d.Point2d Evergreen.V404.CssPixels.CssPixels Evergreen.V404.Touch.ScreenCoordinate
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
