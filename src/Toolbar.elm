module Toolbar exposing
    ( ToolbarElement
    , height
    , link
    , msg
    , view
    , withIcon
    )

import Effect.Browser.Dom as Dom exposing (HtmlId)
import MyUi
import Route exposing (Route)
import Ui exposing (Element)
import Ui.Font
import Ui.Input


type ToolbarElement msg
    = ToolbarElement (Content msg)


type alias Content msg =
    { kind : ElementKind msg
    , title : String
    , icon : Maybe (Element msg)
    , isDisabled : Bool
    , attributes : List (Ui.Attribute msg)
    }


type ElementKind msg
    = LinkButton HtmlId msg Route
    | MsgButton msg HtmlId


link : HtmlId -> (Route -> msg) -> Route -> String -> ToolbarElement msg
link id msg_ route title =
    new (LinkButton id (msg_ route) route) title


msg : HtmlId -> msg -> String -> ToolbarElement msg
msg id msg_ title =
    new (MsgButton msg_ id) title


new : ElementKind msg -> String -> ToolbarElement msg
new kind title =
    ToolbarElement
        { kind = kind
        , title = title
        , icon = Nothing
        , isDisabled = False
        , attributes = []
        }


withIcon : Element msg -> ToolbarElement msg -> ToolbarElement msg
withIcon icon (ToolbarElement element) =
    ToolbarElement { element | icon = Just icon }


mobileItemHeight : number
mobileItemHeight =
    40


view : Bool -> Route -> ToolbarElement msg -> Element msg
view isMobile currentRoute (ToolbarElement element) =
    let
        kindAttr : List (Ui.Attribute msg)
        kindAttr =
            case element.kind of
                LinkButton id msg_ route ->
                    [ if isMobile then
                        Ui.el
                            [ Ui.width (Ui.px 6)
                            , Ui.height Ui.fill
                            , Ui.background MyUi.green500
                            , Ui.alignBottom
                            ]
                            Ui.none
                            |> Ui.inFront
                            |> Ui.attrIf (Route.isSamePage currentRoute route)

                      else
                        Ui.el [ Ui.height (Ui.px 2), Ui.background MyUi.gray, Ui.alignBottom ] Ui.none
                            |> Ui.inFront
                            |> Ui.attrIf (Route.isSamePage currentRoute route)
                    , Dom.idToString id |> Ui.id
                    , Ui.Input.button msg_
                    , MyUi.touchPress msg_
                    , if isMobile then
                        Ui.borderWith { bottom = 1, left = 0, right = 0, top = 0 }

                      else
                        Ui.borderWith { bottom = 0, left = 1, right = 1, top = 0 }
                    ]

                MsgButton msg_ id ->
                    [ Ui.Input.button msg_
                    , MyUi.touchPress msg_
                    , if isMobile then
                        Ui.borderWith { bottom = 1, left = 0, right = 0, top = 0 }

                      else
                        Ui.borderWith { bottom = 0, left = 1, right = 1, top = 0 }
                    , Ui.id (Dom.idToString id)
                    ]
    in
    if isMobile then
        Ui.row
            ([ Ui.background MyUi.secondaryGray
             , Ui.borderColor MyUi.secondaryGrayBorder
             , Ui.paddingXY 16 0
             , Ui.width Ui.fill
             , Ui.height (Ui.px mobileItemHeight)
             ]
                ++ kindAttr
                ++ element.attributes
                ++ [ MyUi.hoverText element.title
                   , Ui.attrIf element.isDisabled (Ui.background (Ui.rgb 200 200 200))
                   , Ui.attrIf element.isDisabled (Ui.Font.color MyUi.gray)
                   ]
            )
            [ viewContent element
            , Ui.el [ Ui.alignRight ] (Ui.text element.title)
            ]

    else
        Ui.el
            ([ Ui.background MyUi.secondaryGray
             , Ui.borderColor MyUi.secondaryGrayBorder
             , Ui.paddingXY 8 0
             , Ui.width Ui.shrink
             , Ui.height (Ui.px height)
             ]
                ++ kindAttr
                ++ element.attributes
                ++ [ MyUi.hoverText element.title
                   , Ui.attrIf element.isDisabled (Ui.background (Ui.rgb 200 200 200))
                   , Ui.attrIf element.isDisabled (Ui.Font.color MyUi.gray)
                   ]
            )
            (Ui.el [ Ui.centerY ] (viewContent element))


height : Int
height =
    30


viewContent : Content msg -> Element msg
viewContent content =
    case content.icon of
        Nothing ->
            Ui.text content.title

        Just icon ->
            icon
