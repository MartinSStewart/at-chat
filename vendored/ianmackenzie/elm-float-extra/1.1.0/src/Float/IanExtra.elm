module Float.IanExtra exposing (equalWithin, interpolateFrom, range)

{-| Convenience functions for working with `Float` values. Examples assume that
this module has been imported using:

    import Float.Extra as Float

@docs equalWithin, interpolateFrom, range

-}

{--Imports for verifying the examples:

   import Float.Extra as Float
-}


{-| Check if two values are equal within a given tolerance.

    Float.equalWithin 1e-6 1.9999 2.0001
    --> False

    Float.equalWithin 1e-3 1.9999 2.0001
    --> True

-}
equalWithin : Float -> Float -> Float -> Bool
equalWithin tolerance firstValue secondValue =
    abs (secondValue - firstValue) <= tolerance


{-| Interpolate from the first value to the second, based on a parameter that
ranges from zero to one. Passing a parameter value of zero will return the start
value and passing a parameter value of one will return the end value.

    Float.interpolateFrom 5 10 0
    --> 5

    Float.interpolateFrom 5 10 1
    --> 10

    Float.interpolateFrom 5 10 0.6
    --> 8

The end value can be less than the start value:

    Float.interpolateFrom 10 5 0.1
    --> 9.5

Parameter values less than zero or greater than one can be used to extrapolate:

    Float.interpolateFrom 5 10 1.5
    --> 12.5

    Float.interpolateFrom 5 10 -0.5
    --> 2.5

    Float.interpolateFrom 10 5 -0.2
    --> 11

-}
interpolateFrom : Float -> Float -> Float -> Float
interpolateFrom start end parameter =
    if parameter <= 0.5 then
        start + parameter * (end - start)

    else
        end + (1 - parameter) * (start - end)


{-| Construct a range of evenly-spaced values given a `start` value, an `end`
value and the number of `steps` to take from the start to the end. The first
value in the returned list will be equal to `start` and the last value will be
equal to `end`. Note that the number of returned values will be one greater than
the number of steps!

    Float.range { start = 0, end = 1, steps = 1 }
    --> [ 0, 1 ]

    Float.range { start = 0, end = 1, steps = 2 }
    --> [ 0, 0.5, 1 ]

    Float.range { start = 10, end = 20, steps = 2 }
    --> [ 10, 15, 20 ]

    Float.range { start = 2, end = 3, steps = 5 }
    --> [ 2, 2.2, 2.4, 2.6, 2.8, 3 ]

The start and end values can be in either order:

    Float.range { start = 1, end = 3, steps = 4 }
    --> [ 1, 1.5, 2, 2.5, 3 ]

    Float.range { start = 3, end = 1, steps = 4 }
    --> [ 3, 2.5, 2, 1.5, 1 ]

Passing a negative or zero `steps` value will result in an empty list being
returned.

If you need finer control over what values get generated, try combining
`interpolateFrom` with the various functions in the
[`elm-1d-parameter`](https://package.elm-lang.org/packages/ianmackenzie/elm-1d-parameter/latest/)
package. For example:

    -- Same as using Float.range
    Parameter1d.steps 5 (Float.interpolateFrom 2 3)
    --> [ 2, 2.2, 2.4, 2.6, 2.8, 3 ]

    -- Omit the last value
    Parameter1d.leading 5 (Float.interpolateFrom 2 3)
    --> [ 2, 2.2, 2.4, 2.6, 2.8 ]

    -- Omit the first value
    Parameter1d.trailing 5 (Float.interpolateFrom 2 3)
    --> [ 2.2, 2.4, 2.6, 2.8, 3 ]

-}
range : { start : Float, end : Float, steps : Int } -> List Float
range { start, end, steps } =
    if steps > 0 then
        rangeHelp start end steps (toFloat steps) []

    else
        []


rangeHelp : Float -> Float -> Int -> Float -> List Float -> List Float
rangeHelp start end i steps accumulatedValues =
    let
        value =
            interpolateFrom start end (toFloat i / steps)

        updatedValues =
            value :: accumulatedValues
    in
    if i == 0 then
        updatedValues

    else
        rangeHelp start end (i - 1) steps updatedValues
