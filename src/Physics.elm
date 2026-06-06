module Physics exposing (Body, bounds, simulate)

{-| A small, purpose built rigid body physics simulation for the game Booby
Trap.

The solver is position-based: each substep predicts where every circle would
move under its current velocity, then resolves overlaps and walls by moving
positions directly (overlapping pairs are split along their contact normal, and
anything outside the box is clamped back in). The new velocity is read out from
how far each circle actually ended up moving.

Because there is no stiff spring, the substep size is no longer pinned by
stability and the caller can use a much smaller number of substeps than the
penalty-based version required.

@docs Body, bounds, simulate

-}

import Array exposing (Array)
import Browser
import Browser.Events
import Duration exposing (Duration)
import Html
import Html.Attributes


{-| A 2D circle: position, velocity and radius. All pegs are assumed to have
the same (unit) mass, which is realistic enough for Booby Trap.
-}
type alias Body =
    { x : Float, y : Float, vx : Float, vy : Float, radius : Float }


{-| The simulation happens inside a fixed square box.
-}
bounds : { min : Float, max : Float }
bounds =
    { min = 0, max = 100 }


{-| How many Gauss-Seidel passes the constraint solver makes per substep. Eight
is a typical value for position-based dynamics and handles small stacks of
contacts.
-}
solverIters : Int
solverIters =
    8


{-| Velocity damping, in units of "per second". Drains kinetic energy so the
world settles instead of jittering forever.
-}
dampingRate : Float
dampingRate =
    2


{-| Sentinel returned from out-of-range `Array.get` calls. Every index used
below is always in range, so this is never observed.
-}
dummyBody : Body
dummyBody =
    { x = 0, y = 0, vx = 0, vy = 0, radius = 0 }


main : Program () (List Body) ()
main =
    Browser.element
        { init =
            \_ ->
                ( List.range 0 10
                    |> List.map
                        (\index ->
                            makeCircle
                                (toFloat index * 10)
                                (modBy 7 index |> toFloat)
                                ((modBy 2 index + 2) * 4 |> toFloat)
                        )
                , Cmd.none
                )
        , update =
            \_ model ->
                ( simulate 4 (Duration.milliseconds 16.6) model
                    |> List.map (\a -> { a | vy = a.vy + 1 })
                , Cmd.none
                )
        , view =
            \model ->
                Html.div
                    []
                    (List.map
                        (\{ x, y, radius } ->
                            Html.div
                                [ Html.Attributes.style "position" "absolute"
                                , Html.Attributes.style "top" (String.fromFloat ((y - radius) * 10) ++ "px")
                                , Html.Attributes.style "left" (String.fromFloat ((x - radius) * 10) ++ "px")
                                , Html.Attributes.style "background-color" "red"
                                , Html.Attributes.style "width" (String.fromFloat (radius * 20) ++ "px")
                                , Html.Attributes.style "height" (String.fromFloat (radius * 20) ++ "px")
                                , Html.Attributes.style "border-radius" "999px"
                                ]
                                []
                        )
                        model
                    )
        , subscriptions = \_ -> Browser.Events.onAnimationFrame (\_ -> ())
        }


makeCircle : Float -> Float -> Float -> Body
makeCircle x y r =
    { x = x, y = y, vx = 0, vy = 0, radius = r }


{-| Run the simulation. `steps` is the number of substeps and `duration` is
how much simulated time should pass in total.
-}
simulate : Int -> Duration -> List Body -> List Body
simulate steps duration bodies =
    let
        durSeconds : Float
        durSeconds =
            Duration.inSeconds duration
    in
    if steps <= 0 || durSeconds <= 0 then
        bodies

    else
        let
            dt : Float
            dt =
                durSeconds / toFloat steps
        in
        stepN steps dt (Array.fromList bodies) |> Array.toList


stepN : Int -> Float -> Array Body -> Array Body
stepN remaining dt bodies =
    if remaining <= 0 then
        bodies

    else
        stepN (remaining - 1) dt (step dt bodies)


{-| One position-based dynamics substep:

1.  Predict where each body would end up under its current velocity.
2.  Run the constraint solver (overlap separation + wall clamping) to push the
    predicted positions into a valid configuration.
3.  Read the new velocity out of the actual position change and apply damping.

-}
step : Float -> Array Body -> Array Body
step dt bodies =
    let
        n : Int
        n =
            Array.length bodies

        damping : Float
        damping =
            Basics.e ^ negate (dampingRate * dt)

        predicted : Array Body
        predicted =
            predictAll 0 n dt bodies bodies

        resolved : Array Body
        resolved =
            solveIters solverIters n predicted
    in
    deriveVelocities 0 n dt damping bodies resolved resolved


{-| Predicted position: each body advances by `velocity * dt`. Velocity carried
through unchanged.
-}
predictAll : Int -> Int -> Float -> Array Body -> Array Body -> Array Body
predictAll i n dt original acc =
    if i - n < 0 then
        let
            b : Body
            b =
                Array.get i original |> Maybe.withDefault dummyBody

            new : Body
            new =
                { x = b.x + b.vx * dt
                , y = b.y + b.vy * dt
                , vx = b.vx
                , vy = b.vy
                , radius = b.radius
                }
        in
        predictAll (i + 1) n dt original (Array.set i new acc)

    else
        acc


{-| Gauss-Seidel relaxation: alternate between resolving overlapping pairs and
clamping bodies back inside the box, for `solverIters` rounds.
-}
solveIters : Int -> Int -> Array Body -> Array Body
solveIters remaining n bodies =
    if remaining <= 0 then
        bodies

    else
        solveIters (remaining - 1) n (clampAll 0 n (resolveAllPairs 0 n bodies))


resolveAllPairs : Int -> Int -> Array Body -> Array Body
resolveAllPairs i n bodies =
    if i + 1 - n < 0 then
        -- i < n - 1: there is at least one j > i to look at.
        let
            bi : Body
            bi =
                Array.get i bodies |> Maybe.withDefault dummyBody
        in
        resolveAllPairs (i + 1) n (resolvePairs i (i + 1) n bi bodies)

    else
        bodies


{-| Walk j = i+1..n-1. If body i and body j overlap, push each one half the
penetration along the contact normal so that they end up exactly touching. The
running `bi` is updated as it moves so subsequent j contacts see the latest
position.
-}
resolvePairs : Int -> Int -> Int -> Body -> Array Body -> Array Body
resolvePairs i j n bi bodies =
    if j - n < 0 then
        let
            bj : Body
            bj =
                Array.get j bodies |> Maybe.withDefault dummyBody

            dx : Float
            dx =
                bj.x - bi.x

            dy : Float
            dy =
                bj.y - bi.y

            dist : Float
            dist =
                sqrt (dx * dx + dy * dy)

            penetration : Float
            penetration =
                bi.radius + bj.radius - dist
        in
        if penetration <= 0 then
            resolvePairs i (j + 1) n bi bodies

        else
            let
                ( nx, ny ) =
                    if 1.0e-9 - dist < 0 then
                        ( dx / dist, dy / dist )

                    else
                        ( 1, 0 )

                half : Float
                half =
                    penetration * 0.5

                biNew : Body
                biNew =
                    { x = bi.x - nx * half
                    , y = bi.y - ny * half
                    , vx = bi.vx
                    , vy = bi.vy
                    , radius = bi.radius
                    }

                bjNew : Body
                bjNew =
                    { x = bj.x + nx * half
                    , y = bj.y + ny * half
                    , vx = bj.vx
                    , vy = bj.vy
                    , radius = bj.radius
                    }
            in
            resolvePairs i (j + 1) n biNew (Array.set j bjNew (Array.set i biNew bodies))

    else
        bodies


clampAll : Int -> Int -> Array Body -> Array Body
clampAll i n bodies =
    if i - n < 0 then
        let
            b : Body
            b =
                Array.get i bodies |> Maybe.withDefault dummyBody

            newX : Float
            newX =
                if b.x - b.radius - bounds.min < 0 then
                    bounds.min + b.radius

                else if bounds.max - b.x - b.radius < 0 then
                    bounds.max - b.radius

                else
                    b.x

            newY : Float
            newY =
                if b.y - b.radius - bounds.min < 0 then
                    bounds.min + b.radius

                else if bounds.max - b.y - b.radius < 0 then
                    bounds.max - b.radius

                else
                    b.y

            clamped : Body
            clamped =
                { x = newX, y = newY, vx = b.vx, vy = b.vy, radius = b.radius }
        in
        clampAll (i + 1) n (Array.set i clamped bodies)

    else
        bodies


{-| The new velocity is the actual displacement (after constraint resolution)
divided by `dt`. A body that got pushed back to where it started has zero
velocity, which is what gives contacts and walls their inelastic feel.
-}
deriveVelocities : Int -> Int -> Float -> Float -> Array Body -> Array Body -> Array Body -> Array Body
deriveVelocities i n dt damping originals resolved acc =
    if i - n < 0 then
        let
            orig : Body
            orig =
                Array.get i originals |> Maybe.withDefault dummyBody

            now : Body
            now =
                Array.get i resolved |> Maybe.withDefault dummyBody

            vx : Float
            vx =
                (now.x - orig.x) / dt * damping

            vy : Float
            vy =
                (now.y - orig.y) / dt * damping

            new : Body
            new =
                { x = now.x, y = now.y, vx = vx, vy = vy, radius = now.radius }
        in
        deriveVelocities (i + 1) n dt damping originals resolved (Array.set i new acc)

    else
        acc
