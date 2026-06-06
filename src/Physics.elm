module Physics exposing
    ( bounds, simulate
    , Body
    )

{-| A small, purpose built rigid body physics simulation for the game Booby
Trap.

Bodies are 2D circles with a position, a velocity and a radius. Each step they
move according to their velocity, bounce off the walls of a fixed bounding box,
and push apart any circles they overlap. Velocity is gently damped so the world
settles instead of jittering forever.

@docs Circle, bounds, simulate

-}

import Array exposing (Array)
import Browser
import Browser.Events
import Duration exposing (Duration)
import Html
import Html.Attributes
import PhysicsFast


{-| The viewer renders two parallel worlds: `old` is stepped by `Physics`,
`new` is stepped by `PhysicsFast`. They start identical, and as long as both
implementations agree the red and blue circles overlap perfectly. Any
divergence is immediately visible as red and blue drifting apart.
-}
type alias Model =
    { old : List Body
    , new : List PhysicsFast.Body
    }


initialBodies : List Body
initialBodies =
    List.range 0 10
        |> List.map
            (\index ->
                makeCircle
                    (toFloat index * 10)
                    (modBy 7 index |> toFloat)
                    ((modBy 2 index + 2) * 4 |> toFloat)
            )


main : Program () Model ()
main =
    Browser.element
        { init =
            \_ ->
                ( { old = initialBodies, new = initialBodies }, Cmd.none )
        , update =
            \_ model ->
                ( { old =
                        simulate 10000 (Duration.milliseconds 16.6) model.old
                            |> List.map (\a -> { a | vy = a.vy + 1 })
                  , new =
                        PhysicsFast.simulate 10000 (Duration.milliseconds 16.6) model.new
                            |> List.map (\a -> { a | vy = a.vy + 1 })
                  }
                , Cmd.none
                )
        , view =
            \model ->
                Html.div
                    []
                    (List.map (viewCircle "red") model.old
                        ++ List.map (viewCircle "blue") model.new
                    )
        , subscriptions = \_ -> Browser.Events.onAnimationFrame (\_ -> ())
        }


viewCircle : String -> { a | x : Float, y : Float, radius : Float } -> Html.Html msg
viewCircle color { x, y, radius } =
    Html.div
        [ Html.Attributes.style "position" "absolute"
        , Html.Attributes.style "top" (String.fromFloat ((y - radius) * 10) ++ "px")
        , Html.Attributes.style "left" (String.fromFloat ((x - radius) * 10) ++ "px")
        , Html.Attributes.style "background-color" color
        , Html.Attributes.style "width" (String.fromFloat (radius * 20) ++ "px")
        , Html.Attributes.style "height" (String.fromFloat (radius * 20) ++ "px")
        , Html.Attributes.style "border-radius" "999px"
        , Html.Attributes.style "mix-blend-mode" "multiply"
        ]
        []


makeCircle : Float -> Float -> Float -> Body
makeCircle x y r =
    { x = x, y = y, vx = 0, vy = 0, radius = r, mass = max r 1.0e-6 ^ 2 }


{-| The simulation happens inside a fixed square box centered on the origin.
Circles bounce off the walls and are always kept fully inside it.
-}
bounds : { min : Float, max : Float }
bounds =
    { min = 0, max = 100 }


{-| Internal simulation state. Mass is proportional to area (radius squared) so
that contacts conserve momentum: a small circle is shoved further than a large
one when they collide.
-}
type alias Body =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    , radius : Float
    , mass : Float
    }


{-| How hard overlapping circles push each other apart, per unit of
penetration. Higher values separate faster but need smaller time steps to stay
stable.
-}
stiffness : Float
stiffness =
    200000


{-| Velocity damping, in units of "per second". Drains kinetic energy so the
world settles instead of bouncing forever.
-}
dampingRate : Float
dampingRate =
    2


{-| Run the simulation.

  - `steps` is the number of integration steps. More steps means a smaller time
    step per integration, which is more accurate and more stable.
  - `duration` is how much simulated time should pass in total.
  - the circles are the bodies to simulate.

Returns the circles in the same order, with updated positions and velocities.

-}
simulate : Int -> Duration -> List Body -> List Body
simulate steps duration circles =
    if steps <= 0 then
        circles

    else
        let
            dt : Float
            dt =
                Duration.inSeconds duration / toFloat steps

            initial : Array Body
            initial =
                circles |> Array.fromList

            settled : Array Body
            settled =
                List.range 1 steps
                    |> List.foldl (\_ bodies -> step dt bodies) initial
        in
        settled |> Array.toList


{-| Advance the whole system by one time step using semi-implicit Euler:
compute contact forces from the current positions, integrate velocities (with
damping), integrate positions from the new velocities, then bounce anything that
has run into a wall.
-}
step : Float -> Array Body -> Array Body
step dt bodies =
    let
        forces : Array ( Float, Float )
        forces =
            contactForces bodies

        damping : Float
        damping =
            Basics.e ^ negate (dampingRate * dt)
    in
    Array.indexedMap
        (\i body ->
            let
                ( fx, fy ) =
                    Array.get i forces |> Maybe.withDefault ( 0, 0 )

                vx =
                    (body.vx + fx / body.mass * dt) * damping

                vy =
                    (body.vy + fy / body.mass * dt) * damping
            in
            { vx = vx
            , vy = vy
            , x = body.x + vx * dt
            , y = body.y + vy * dt
            , radius = body.radius
            , mass = body.mass
            }
                |> resolveWalls
        )
        bodies


{-| Keep a body fully inside the bounding box. If it has crossed a wall, place
it back against the wall and reflect the velocity component so it points back
into the box.
-}
resolveWalls : Body -> Body
resolveWalls body =
    let
        ( x, vx ) =
            bounce body.x body.vx body.radius

        ( y, vy ) =
            bounce body.y body.vy body.radius
    in
    { x = x, y = y, vx = vx, vy = vy, radius = body.radius, mass = body.mass }


bounce : Float -> Float -> Float -> ( Float, Float )
bounce pos vel radius =
    if pos - radius < bounds.min then
        ( bounds.min + radius, abs vel )

    else if pos + radius > bounds.max then
        ( bounds.max - radius, negate (abs vel) )

    else
        ( pos, vel )


{-| For every body, sum the repulsion from every other body it overlaps. Forces
are computed from the current positions of all bodies (so the result does not
depend on iteration order), and each contact pushes the pair apart along the
line between their centers with equal and opposite force.
-}
contactForces : Array Body -> Array ( Float, Float )
contactForces bodies =
    let
        indexed : List ( Int, Body )
        indexed =
            Array.toIndexedList bodies
    in
    indexed
        |> List.map
            (\( i, bi ) ->
                List.foldl
                    (\( j, bj ) ( fx, fy ) ->
                        if i == j then
                            ( fx, fy )

                        else
                            let
                                dx =
                                    bj.x - bi.x

                                dy =
                                    bj.y - bi.y

                                dist =
                                    sqrt (dx * dx + dy * dy)

                                penetration =
                                    bi.radius + bj.radius - dist
                            in
                            if penetration <= 0 then
                                ( fx, fy )

                            else
                                let
                                    -- Unit vector pointing from bi toward bj.
                                    -- If the centers coincide, pick an
                                    -- arbitrary but deterministic direction.
                                    ( nx, ny ) =
                                        if dist > 1.0e-9 then
                                            ( dx / dist, dy / dist )

                                        else
                                            ( 1, 0 )

                                    magnitude =
                                        stiffness * penetration
                                in
                                -- Push bi away from bj (opposite the normal).
                                ( fx - nx * magnitude, fy - ny * magnitude )
                    )
                    ( 0, 0 )
                    indexed
            )
        |> Array.fromList
