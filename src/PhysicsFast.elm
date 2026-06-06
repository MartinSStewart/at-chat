module PhysicsFast exposing (Body, bounds, simulate)

{-| An optimized variant of `Physics.simulate`.

It is intentionally a duplicate of `Physics`, kept side by side so that any
regressions introduced while optimizing can be spotted by running both
simulations in parallel and comparing.

Compared to `Physics` it:

  - uses `Body` everywhere (mass is part of the public record so there is no
    `Circle` ⟷ `Body` conversion on the way in or out);
  - never uses record update syntax in the inner loops;
  - replaces `List.foldl` / `List.map` / `List.range` in the hot loops with
    hand-written tail-recursive functions;
  - writes numeric comparisons as `a - b < 0` so the Elm compiler can emit a
    raw JS `<` instead of going through the polymorphic comparison helper.

@docs Body, bounds, simulate

-}

import Array exposing (Array)
import Duration exposing (Duration)


{-| A 2D circle: position, velocity, radius and mass. Mass is provided by the
caller (typical choice: `radius * radius`, i.e. proportional to area).
-}
type alias Body =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    , radius : Float
    , mass : Float
    }


{-| The simulation happens inside a fixed square box centered on the origin.
-}
bounds : { min : Float, max : Float }
bounds =
    { min = -10, max = 10 }


stiffness : Float
stiffness =
    200


dampingRate : Float
dampingRate =
    4


{-| Sentinel returned from out-of-range `Array.get` calls. Every index used
below is always in range, so this is never observed.
-}
dummyBody : Body
dummyBody =
    { x = 0, y = 0, vx = 0, vy = 0, radius = 0, mass = 1 }


{-| Run the simulation. See `Physics.simulate` for the semantics.
-}
simulate : Int -> Duration -> List Body -> List Body
simulate steps duration bodies =
    if steps <= 0 then
        bodies

    else
        let
            dt : Float
            dt =
                Duration.inSeconds duration / toFloat steps
        in
        stepN steps dt (Array.fromList bodies) |> Array.toList


{-| Tail-recursive replacement for `List.foldl (\_ -> step dt) initial (List.range 1 steps)`.
-}
stepN : Int -> Float -> Array Body -> Array Body
stepN remaining dt bodies =
    if remaining <= 0 then
        bodies

    else
        stepN (remaining - 1) dt (step dt bodies)


step : Float -> Array Body -> Array Body
step dt bodies =
    let
        n : Int
        n =
            Array.length bodies

        forces : Array ( Float, Float )
        forces =
            computeForces 0 n bodies (Array.repeat n ( 0, 0 ))

        damping : Float
        damping =
            Basics.e ^ negate (dampingRate * dt)
    in
    advanceAll 0 n dt damping bodies forces bodies


{-| Walk every body, integrate its velocity and position, bounce it off the
walls, and write the result into a fresh array. No record update syntax.
-}
advanceAll : Int -> Int -> Float -> Float -> Array Body -> Array ( Float, Float ) -> Array Body -> Array Body
advanceAll i n dt damping bodies forces acc =
    if i - n < 0 then
        let
            body : Body
            body =
                Array.get i bodies |> Maybe.withDefault dummyBody

            ( fx, fy ) =
                Array.get i forces |> Maybe.withDefault ( 0, 0 )

            vxRaw : Float
            vxRaw =
                (body.vx + fx / body.mass * dt) * damping

            vyRaw : Float
            vyRaw =
                (body.vy + fy / body.mass * dt) * damping

            xRaw : Float
            xRaw =
                body.x + vxRaw * dt

            yRaw : Float
            yRaw =
                body.y + vyRaw * dt

            ( x1, vx1 ) =
                if xRaw - body.radius - bounds.min < 0 then
                    ( bounds.min + body.radius, abs vxRaw )

                else if bounds.max - xRaw - body.radius < 0 then
                    ( bounds.max - body.radius, -(abs vxRaw) )

                else
                    ( xRaw, vxRaw )

            ( y1, vy1 ) =
                if yRaw - body.radius - bounds.min < 0 then
                    ( bounds.min + body.radius, abs vyRaw )

                else if bounds.max - yRaw - body.radius < 0 then
                    ( bounds.max - body.radius, -(abs vyRaw) )

                else
                    ( yRaw, vyRaw )

            newBody : Body
            newBody =
                { x = x1
                , y = y1
                , vx = vx1
                , vy = vy1
                , radius = body.radius
                , mass = body.mass
                }
        in
        advanceAll (i + 1) n dt damping bodies forces (Array.set i newBody acc)

    else
        acc


{-| Walk every body i and fill in `forces[i]` with the total repulsion from
every other body.
-}
computeForces : Int -> Int -> Array Body -> Array ( Float, Float ) -> Array ( Float, Float )
computeForces i n bodies forces =
    if i - n < 0 then
        let
            bi : Body
            bi =
                Array.get i bodies |> Maybe.withDefault dummyBody

            ( fx, fy ) =
                sumForce i 0 n bi bodies 0 0
        in
        computeForces (i + 1) n bodies (Array.set i ( fx, fy ) forces)

    else
        forces


{-| Tail-recursive replacement for the inner `List.foldl` over the other
bodies. `fx` and `fy` are threaded as plain Float arguments instead of as a
tuple, so the compiler turns the recursion into a `while` loop with zero
per-iteration allocation.
-}
sumForce : Int -> Int -> Int -> Body -> Array Body -> Float -> Float -> ( Float, Float )
sumForce i j n bi bodies fx fy =
    if j - n < 0 then
        if i == j then
            sumForce i (j + 1) n bi bodies fx fy

        else
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
                sumForce i (j + 1) n bi bodies fx fy

            else
                let
                    magnitude : Float
                    magnitude =
                        stiffness * penetration

                    -- Match the floating-point operation order of `Physics`
                    -- exactly so both implementations agree bit-for-bit.
                    ( nx, ny ) =
                        if 1.0e-9 - dist < 0 then
                            ( dx / dist, dy / dist )

                        else
                            ( 1, 0 )
                in
                sumForce i (j + 1) n bi bodies (fx - nx * magnitude) (fy - ny * magnitude)

    else
        ( fx, fy )
