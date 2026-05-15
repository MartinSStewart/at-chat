module Gremlin exposing
    ( gremlinHeight
    , gremlinWidth
    , pickGremlinTargetMessage
    , pickGremlinWord
    , view
    )

import Array
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Html
import Html.Attributes
import LocalState exposing (LocalState)
import Ports exposing (WordBoundingBox)
import SeqDict
import Types exposing (LoggedIn2)
import Ui exposing (Element)


gremlinWidth : Float
gremlinWidth =
    -- Source frames are 112 x 150 px; we render the gremlin at 2x the
    -- previous on-screen size (was 28 tall, now 56).
    toFloat (round (gremlinHeight * 112 / 150))


gremlinHeight : Float
gremlinHeight =
    56


pickGremlinTargetMessage : Int -> LocalState -> Maybe HtmlId
pickGremlinTargetMessage counter local =
    let
        allIndices : List Int
        allIndices =
            SeqDict.values local.guilds
                |> List.concatMap (\guild -> SeqDict.values guild.channels)
                |> List.concatMap (\channel -> List.range 0 (Array.length channel.messages - 1))
    in
    case allIndices of
        [] ->
            Nothing

        _ ->
            let
                index : Int
                index =
                    modBy (List.length allIndices) (max 0 counter)
            in
            allIndices
                |> List.drop index
                |> List.head
                |> Maybe.map (\i -> "guild_message_" ++ String.fromInt i |> Dom.id)


pickGremlinWord : List WordBoundingBox -> Maybe WordBoundingBox
pickGremlinWord boxes =
    -- Prefer the widest word so the gremlin has somewhere comfortable to sit.
    case boxes of
        [] ->
            Nothing

        first :: rest ->
            List.foldl
                (\b best ->
                    if b.width > best.width then
                        b

                    else
                        best
                )
                first
                rest
                |> Just


view : LoggedIn2 -> Element msg
view loggedIn =
    case ( loggedIn.enableGremlins, loggedIn.gremlinSpot ) of
        ( True, Just spot ) ->
            let
                frameNumber : Int
                frameNumber =
                    modBy 3 loggedIn.gremlinTick + 1
            in
            Ui.html
                (Html.img
                    [ Html.Attributes.src
                        ("/gremlins/outline-guy-sit-frame-"
                            ++ String.fromInt frameNumber
                            ++ ".png"
                        )
                    , Html.Attributes.alt ""
                    , Html.Attributes.style "position" "absolute"
                    , Html.Attributes.style "left" (String.fromFloat spot.x ++ "px")
                    , Html.Attributes.style "top" (String.fromFloat spot.y ++ "px")
                    , Html.Attributes.style "width" (String.fromFloat gremlinWidth ++ "px")
                    , Html.Attributes.style "height" (String.fromFloat gremlinHeight ++ "px")
                    , Html.Attributes.style "image-rendering" "pixelated"
                    , Html.Attributes.style "pointer-events" "none"
                    , Html.Attributes.style "z-index" "5"
                    ]
                    []
                )

        _ ->
            Ui.none
