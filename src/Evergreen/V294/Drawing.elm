module Evergreen.V294.Drawing exposing (..)

import Date
import Evergreen.V294.CssPixels
import Evergreen.V294.FileStatus
import Evergreen.V294.Id
import Evergreen.V294.Point2d
import Evergreen.V294.Touch
import List.Nonempty
import SeqDict


type alias Stroke =
    { points : List.Nonempty.Nonempty ( Float, Float )
    }


type alias Drawing userId =
    { finished :
        List
            { createdBy : userId
            , points : List.Nonempty.Nonempty ( Float, Float )
            }
    , inProgress : SeqDict.SeqDict userId Stroke
    , undone : SeqDict.SeqDict userId (List Stroke)
    }


type MessageAnchor
    = UserIconAnchor
    | TimestampAnchor
    | ImageAttachmentAnchor (Evergreen.V294.Id.Id Evergreen.V294.FileStatus.FileId)
    | EmbedImageAnchor Int


type AnchorType
    = MessageAnchor Evergreen.V294.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V294.Id.ThreadRoute Date.Date


type LocalChange
    = StartStroke ( Float, Float )
    | ContinueStroke (List.Nonempty.Nonempty ( Float, Float ))
    | EndStroke (List ( Float, Float ))
    | UndoStroke
    | RedoStroke


type alias ActiveStroke =
    { unsent : List ( Float, Float )
    }


type alias SelectedAnchorData =
    { guildOrDmId : Evergreen.V294.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V294.Point2d.Point2d Evergreen.V294.CssPixels.CssPixels Evergreen.V294.Touch.ScreenCoordinate
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


type Msg
    = MouseDown Float Float
    | MouseMoved Float Float
    | MouseUp
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
