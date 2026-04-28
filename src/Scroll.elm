module Scroll exposing
    ( smoothScroll
    , smoothScrollBy
    , toBottomOfChannel
    , toBottomOfChannelIfAtBottom
    , toBottomOfChannelSmooth
    )

import Ease
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Task as Task exposing (Task)
import Pages.Guild
import Types exposing (FrontendMsg(..), ScrollPosition(..))


smoothScroll : HtmlId -> Task FrontendOnly Dom.Error ()
smoothScroll targetId =
    Task.map2
        Tuple.pair
        (Dom.getElement targetId)
        (Dom.getViewportOf Pages.Guild.conversationContainerId)
        |> Task.andThen
            (\( { element }, { viewport } ) ->
                if element.y > 0 then
                    Dom.setViewportOf
                        Pages.Guild.conversationContainerId
                        0
                        (viewport.y + element.y - Pages.Guild.channelHeaderHeight)

                else
                    smoothScrollY
                        0
                        viewport.x
                        viewport.y
                        (viewport.y + element.y - Pages.Guild.channelHeaderHeight)
            )


smoothScrollBy : Float -> Task FrontendOnly Dom.Error ()
smoothScrollBy scrollYAmount =
    Task.andThen
        (\{ viewport } -> smoothScrollY 0 viewport.x viewport.y (viewport.y + scrollYAmount))
        (Dom.getViewportOf Pages.Guild.conversationContainerId)


smoothScrollSteps : number
smoothScrollSteps =
    20


smoothScrollY : Int -> Float -> Float -> Float -> Task FrontendOnly Dom.Error ()
smoothScrollY stepCount x startY endY =
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
        Dom.setViewportOf Pages.Guild.conversationContainerId x y
            |> Task.andThen (\() -> smoothScrollY (stepCount + 1) x startY endY)


toBottomOfChannel : Command FrontendOnly toMsg FrontendMsg
toBottomOfChannel =
    Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999 |> Task.attempt (\_ -> SetScrollToBottom)


toBottomOfChannelIfAtBottom : ScrollPosition -> Command FrontendOnly toMsg FrontendMsg
toBottomOfChannelIfAtBottom position =
    case position of
        ScrolledToBottom ->
            toBottomOfChannel

        ScrolledToTop ->
            Command.none

        ScrolledToMiddle ->
            Command.none


toBottomOfChannelSmooth : Command FrontendOnly toMsg FrontendMsg
toBottomOfChannelSmooth =
    Dom.getViewportOf Pages.Guild.conversationContainerId
        |> Task.andThen
            (\{ scene, viewport } ->
                toBottomOfChannelSmoothHelper viewport.y (scene.height - viewport.height) 0
            )
        |> Task.attempt (\_ -> SetScrollToBottom)


toBottomOfChannelSmoothHelper : Float -> Float -> Int -> Task FrontendOnly Dom.Error ()
toBottomOfChannelSmoothHelper startY endY count =
    if count <= smoothScrollSteps then
        let
            t =
                toFloat count / smoothScrollSteps

            y =
                t * (endY - startY) + startY
        in
        Dom.setViewportOf Pages.Guild.conversationContainerId 0 y
            |> Task.andThen (\() -> toBottomOfChannelSmoothHelper startY endY (count + 1))

    else
        Task.succeed ()
