module Scroll exposing (smoothScroll, toBottomOfChannel, toBottomOfChannelSmooth)

import Ease
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command exposing (Command, FrontendOnly)
import Effect.Task as Task exposing (Task)
import Pages.Guild
import Types exposing (FrontendMsg(..))


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


smoothScrollSteps : number
smoothScrollSteps =
    20


smoothScrollY : Int -> Float -> Float -> Float -> Task FrontendOnly Dom.Error ()
smoothScrollY stepsLeft x startY endY =
    let
        t =
            toFloat stepsLeft / smoothScrollSteps |> Ease.inOutQuart

        y : Float
        y =
            startY + (endY - startY) * t
    in
    if stepsLeft > smoothScrollSteps then
        Task.succeed ()

    else
        Dom.setViewportOf Pages.Guild.conversationContainerId x y
            |> Task.andThen (\() -> smoothScrollY (stepsLeft + 1) x startY endY)


toBottomOfChannel : Command FrontendOnly toMsg FrontendMsg
toBottomOfChannel =
    Dom.setViewportOf Pages.Guild.conversationContainerId 0 9999999 |> Task.attempt (\_ -> SetScrollToBottom)


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
