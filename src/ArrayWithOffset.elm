module ArrayWithOffset exposing (ArrayWithOffset, foldArrayNewToOld, get, init, initFromSlice, last, length, push, set, update)

import Array exposing (Array)
import Dict exposing (Dict)
import Id exposing (Id)
import Message exposing (Message, MessageState(..))


type alias ArrayWithOffset messageId userId =
    { offset : Int, array : Array (Message messageId userId), size : Int, sparseItems : Dict Int (Message messageId userId) }


init : ArrayWithOffset messageId userId
init =
    { offset = 0, array = Array.empty, size = 0, sparseItems = Dict.empty }


initFromSlice : Int -> Int -> Array (Message messageId userId) -> ArrayWithOffset messageId userId
initFromSlice start end array =
    { offset = start
    , array = Array.slice start end array
    , size = Array.length array
    , sparseItems = Dict.empty
    }


get : Id messageId -> ArrayWithOffset messageId userId -> Maybe (MessageState messageId userId)
get messageId { offset, array, size, sparseItems } =
    let
        index =
            Id.toInt messageId
    in
    if index < 0 || index >= size then
        Nothing

    else
        case Array.get (index - offset) array of
            Just message ->
                MessageLoaded message |> Just

            Nothing ->
                case Dict.get index sparseItems of
                    Just message ->
                        MessageLoaded message |> Just

                    Nothing ->
                        Just MessageUnloaded


set : Id messageId -> Message messageId userId -> ArrayWithOffset messageId userId -> ArrayWithOffset messageId userId
set messageId message { offset, array, size, sparseItems } =
    let
        index =
            Id.toInt messageId
    in
    if index < 0 || index >= size then
        { offset = offset, array = array, size = size, sparseItems = sparseItems }

    else
        let
            index2 =
                index - offset
        in
        if index2 < 0 || index2 >= Array.length array then
            { offset = offset, array = array, size = size, sparseItems = Dict.insert index message sparseItems }

        else
            { offset = offset
            , array = Array.set index2 message array
            , size = size
            , sparseItems = sparseItems
            }


update :
    Id messageId
    -> (Message messageId userId -> Message messageId userId)
    -> ArrayWithOffset messageId userId
    -> ArrayWithOffset messageId userId
update messageId updateFunc { offset, array, size, sparseItems } =
    let
        index =
            Id.toInt messageId
    in
    if index < 0 || index >= size then
        { offset = offset, array = array, size = size, sparseItems = sparseItems }

    else
        case Array.get (index - offset) array of
            Just message ->
                { offset = offset
                , array = Array.set (index - offset) (updateFunc message) array
                , size = size
                , sparseItems = sparseItems
                }

            Nothing ->
                { offset = offset
                , array = array
                , size = size
                , sparseItems = Dict.update index (Maybe.map updateFunc) sparseItems
                }


push : Message messageId userId -> ArrayWithOffset messageId userId -> ArrayWithOffset messageId userId
push message { offset, array, size, sparseItems } =
    { offset = offset, array = array, size = size + 1, sparseItems = Dict.insert size message sparseItems }


length : ArrayWithOffset messageId userId -> Int
length arrayWithOffset =
    arrayWithOffset.size


last : ArrayWithOffset messageId userId -> Maybe (MessageState messageId userId)
last arrayWithOffset =
    get (Id.fromInt (arrayWithOffset.size - 1)) arrayWithOffset


foldArrayNewToOld : (Id messageId -> Message messageId userId -> a -> a) -> a -> ArrayWithOffset messageId userId -> a
foldArrayNewToOld foldFunc a data =
    Array.foldr
        (\message ( index, a2 ) -> ( index - 1, foldFunc (Id.fromInt index) message a2 ))
        ( data.offset + Array.length data.array - 1, a )
        data.array
        |> Tuple.second



--foldNewToOld : (MessageState messageId userId -> a -> a) -> a -> ArrayWithOffset messageId userId -> a
--foldNewToOld foldFunc a { offset, array, size, sparseItems } =
--    Dict.foldr
--        (\messageId message a2 ->
--            if Id.toInt messageId <  a2
--        )
--        a
--        sparseItems
