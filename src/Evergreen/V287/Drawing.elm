module Evergreen.V287.Drawing exposing (..)

import Date
import Evergreen.V287.CssPixels
import Evergreen.V287.FileStatus
import Evergreen.V287.Id
import Evergreen.V287.Point2d
import Evergreen.V287.Touch
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
    | ImageAttachmentAnchor (Evergreen.V287.Id.Id Evergreen.V287.FileStatus.FileId)
    | EmbedImageAnchor Int


type AnchorType
    = MessageAnchor Evergreen.V287.Id.ThreadRouteWithMessage MessageAnchor
    | DateDividerAnchor Evergreen.V287.Id.ThreadRoute Date.Date


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
    { guildOrDmId : Evergreen.V287.Id.AnyGuildOrDmId
    , anchorType : AnchorType
    , position : Evergreen.V287.Point2d.Point2d Evergreen.V287.CssPixels.CssPixels Evergreen.V287.Touch.ScreenCoordinate
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
