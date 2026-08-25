module Scroll exposing
    ( ScrollPosition(..)
    , closeToTop
    , decodeScrollToBottom
    , smoothScroll
    , smoothScrollBy
    , smoothScrollTo
    , smoothScrollToTopOf
    , toBottomOfChannel
    , toBottomOfChannelIfAtBottom
    , toBottomOfChannelSmooth
    )

import Ease
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Task as Task exposing (Task)
import Json.Decode
import MyUi
import Ports


type ScrollPosition
    = ScrolledToBottom
    | ScrolledToTop
    | ScrolledToMiddle


closeToTop : number
closeToTop =
    300


decodeScrollToBottom : (ScrollPosition -> msg) -> ScrollPosition -> Json.Decode.Decoder msg
decodeScrollToBottom onScroll currentScrollPosition =
    Json.Decode.map3
        (\scrollTop scrollHeight clientHeight ->
            if scrollTop + clientHeight >= scrollHeight - 5 then
                ScrolledToBottom

            else if scrollTop <= closeToTop then
                ScrolledToTop

            else
                ScrolledToMiddle
        )
        (Json.Decode.at [ "target", "scrollTop" ] Json.Decode.float)
        (Json.Decode.at [ "target", "scrollHeight" ] Json.Decode.float)
        (Json.Decode.at [ "target", "clientHeight" ] Json.Decode.float)
        |> Json.Decode.andThen
            (\scrollPosition ->
                if scrollPosition == currentScrollPosition then
                    Json.Decode.fail ""

                else
                    onScroll scrollPosition |> Json.Decode.succeed
            )


smoothScroll : HtmlId -> HtmlId -> Task FrontendOnly Dom.Error ()
smoothScroll conversationContainerId targetId =
    Task.map2
        Tuple.pair
        (Dom.getElement targetId)
        (Dom.getViewportOf conversationContainerId)
        |> Task.andThen
            (\( { element }, { viewport } ) ->
                if element.y > 0 then
                    Dom.setViewportOf
                        conversationContainerId
                        0
                        (viewport.y + element.y - MyUi.channelHeaderHeight)

                else
                    smoothScrollY
                        conversationContainerId
                        0
                        viewport.x
                        viewport.y
                        (viewport.y + element.y - MyUi.channelHeaderHeight)
            )


{-| Animates the whole way to the target. `smoothScroll` jumps instantly when the target starts
out at or below the top of the window, which is fine when we've just switched channel and there's
nothing on screen worth following, but jarring when the user is staying put and only moving to
another message in the conversation they're already reading.
-}
smoothScrollTo : HtmlId -> HtmlId -> Task FrontendOnly Dom.Error ()
smoothScrollTo conversationContainerId targetId =
    Task.map2
        Tuple.pair
        (Dom.getElement targetId)
        (Dom.getViewportOf conversationContainerId)
        |> Task.andThen
            (\( { element }, { viewport } ) ->
                smoothScrollY
                    conversationContainerId
                    0
                    viewport.x
                    viewport.y
                    (viewport.y + element.y - MyUi.channelHeaderHeight)
            )


{-| Smooth scroll a container so the target ends up at the top of it. `smoothScroll` and
`smoothScrollTo` assume the container starts right below the channel header; this works out
where it actually starts, so it also does the right thing for a tab drawn over the
conversation.
-}
smoothScrollToTopOf : HtmlId -> HtmlId -> Task FrontendOnly Dom.Error ()
smoothScrollToTopOf containerId targetId =
    Task.map3
        (\target container { viewport } ->
            smoothScrollY
                containerId
                0
                viewport.x
                viewport.y
                (viewport.y + target.element.y - container.element.y)
        )
        (Dom.getElement targetId)
        (Dom.getElement containerId)
        (Dom.getViewportOf containerId)
        |> Task.andThen identity


smoothScrollBy : HtmlId -> Float -> Command FrontendOnly toMsg msg
smoothScrollBy conversationContainerId scrollYAmount =
    Ports.smoothScrollBy conversationContainerId scrollYAmount


smoothScrollSteps : number
smoothScrollSteps =
    30


smoothScrollY : HtmlId -> Int -> Float -> Float -> Float -> Task FrontendOnly Dom.Error ()
smoothScrollY conversationContainerId stepCount x startY endY =
    let
        t =
            toFloat stepCount / smoothScrollSteps |> Ease.inOutQuart

        y : Float
        y =
            startY + (endY - startY) * t
    in
    if stepCount > smoothScrollSteps then
        Task.succeed ()

    else
        Dom.setViewportOf conversationContainerId x y
            |> Task.andThen (\() -> smoothScrollY conversationContainerId (stepCount + 1) x startY endY)


toBottomOfChannel : HtmlId -> msg -> Command FrontendOnly toMsg msg
toBottomOfChannel conversationContainerId setScrollToBottom =
    Dom.setViewportOf conversationContainerId 0 9999999 |> Task.attempt (\_ -> setScrollToBottom)


toBottomOfChannelIfAtBottom : HtmlId -> msg -> ScrollPosition -> Command FrontendOnly toMsg msg
toBottomOfChannelIfAtBottom conversationContainerId setScrollToBottom position =
    case position of
        ScrolledToBottom ->
            toBottomOfChannel conversationContainerId setScrollToBottom

        ScrolledToTop ->
            Command.none

        ScrolledToMiddle ->
            Command.none


toBottomOfChannelSmooth : HtmlId -> msg -> Command FrontendOnly toMsg msg
toBottomOfChannelSmooth conversationContainerId setScrollToBottom =
    Dom.getViewportOf conversationContainerId
        |> Task.andThen
            (\{ scene, viewport } ->
                toBottomOfChannelSmoothHelper conversationContainerId viewport.y (scene.height - viewport.height) 0
            )
        |> Task.attempt (\_ -> setScrollToBottom)


toBottomOfChannelSmoothHelper : HtmlId -> Float -> Float -> Int -> Task FrontendOnly Dom.Error ()
toBottomOfChannelSmoothHelper conversationContainerId startY endY count =
    if count <= smoothScrollSteps then
        let
            t =
                toFloat count / smoothScrollSteps

            y =
                t * (endY - startY) + startY
        in
        Dom.setViewportOf conversationContainerId 0 y
            |> Task.andThen (\() -> toBottomOfChannelSmoothHelper conversationContainerId startY endY (count + 1))

    else
        Task.succeed ()
