module Evergreen.V288.Drawing exposing (..)

import Date
import Evergreen.V288.CssPixels
import Evergreen.V288.FileStatus
import Evergreen.V288.Id
import Evergreen.V288.Point2d
import Evergreen.V288.Touch
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
    | ImageAttachmentAnchor (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId)
    | EmbedImageAnchor Int


type AnchorType
    = MessageAnchor Evergreen.V288.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V288.Id.ThreadRoute Date.Date


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
    { guildOrDmId : Evergreen.V288.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V288.Point2d.Point2d Evergreen.V288.CssPixels.CssPixels Evergreen.V288.Touch.ScreenCoordinate
    , pointScale : Float
    , stroke : Maybe ActiveStroke
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
