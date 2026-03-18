module Touch exposing (ScreenCoordinate(..), Touch, averageTouchMove, decodeTouchEvent)

import CssPixels exposing (CssPixels)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Json.Decode exposing (Decoder)
import NonemptyDict exposing (NonemptyDict)
import Point2d exposing (Point2d)
import Quantity exposing (Quantity)
import Time
import Vector2d exposing (Vector2d)


type alias Touch =
    { client : Point2d CssPixels ScreenCoordinate
    , target : Maybe HtmlId
    }


type ScreenCoordinate
    = ScreenCoordinate Never


decodeTouchEvent : (Time.Posix -> NonemptyDict Int Touch -> msg) -> Decoder msg
decodeTouchEvent msg =
    Json.Decode.map2
        Tuple.pair
        (Json.Decode.field "touches" (dynamicListOf decodeTouch))
        (Json.Decode.field "timeStamp" Json.Decode.float)
        |> Json.Decode.andThen
            (\( list, time ) ->
                case NonemptyDict.fromList list of
                    Just nonempty ->
                        msg (round time |> Time.millisToPosix) nonempty |> Json.Decode.succeed

                    Nothing ->
                        Json.Decode.fail ""
            )


decodeTouch : Decoder ( Int, Touch )
decodeTouch =
    Json.Decode.map4
        (\identifier clientX clientY target ->
            ( identifier, { client = Point2d.xy clientX clientY, target = target } )
        )
        (Json.Decode.field "identifier" Json.Decode.int)
        (Json.Decode.field "clientX" decodeQuantity)
        (Json.Decode.field "clientY" decodeQuantity)
        (Json.Decode.field "target" (decodeId 10))


decodeId : Int -> Decoder (Maybe HtmlId)
decodeId depth =
    if depth > 0 then
        Json.Decode.field "id" Json.Decode.string
            |> Json.Decode.andThen
                (\id ->
                    if id == "" then
                        Json.Decode.field
                            "parentElement"
                            (Json.Decode.nullable (decodeId (depth - 1)) |> Json.Decode.map (Maybe.andThen identity))

                    else
                        Json.Decode.succeed (Just (Dom.id id))
                )

    else
        Json.Decode.succeed Nothing


decodeQuantity : Decoder (Quantity Float unit)
decodeQuantity =
    Json.Decode.map Quantity.unsafe Json.Decode.float


dynamicListOf : Decoder a -> Decoder (List a)
dynamicListOf itemDecoder =
    let
        decodeN n =
            List.range 0 (n - 1)
                |> List.map decodeOne
                |> List.foldr (Json.Decode.map2 (::)) (Json.Decode.succeed [])

        decodeOne n =
            Json.Decode.field (String.fromInt n) itemDecoder
    in
    Json.Decode.field "length" Json.Decode.int
        |> Json.Decode.andThen decodeN


averageTouchMove : NonemptyDict Int Touch -> NonemptyDict Int Touch -> Vector2d CssPixels ScreenCoordinate
averageTouchMove oldTouches newTouches =
    NonemptyDict.merge
        (\_ _ state -> state)
        (\_ new old state ->
            { total = Vector2d.plus state.total (Vector2d.from old.client new.client)
            , count = state.count + 1
            }
        )
        (\_ _ state -> state)
        newTouches
        oldTouches
        { total = Vector2d.zero, count = 0 }
        |> (\a ->
                if a.count > 0 then
                    a.total |> Vector2d.divideBy a.count

                else
                    Vector2d.zero
           )
