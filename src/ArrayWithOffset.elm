module ArrayWithOffset exposing (ArrayWithOffset, get, init)

import Array exposing (Array)
import Dict exposing (Dict)
import Id exposing (Id)
import Message exposing (Message, MessageState(..))


type alias ArrayWithOffset messageId userId =
    { offset : Int, array : Array (Message messageId userId), size : Int, sparseItems : Dict Int (Message messageId userId) }


init : ArrayWithOffset messageId userId
init =
    { offset = 0, array = Array.empty, size = 0, sparseItems = Dict.empty }


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



--set : Id messageId -> Message messageId userId -> ArrayWithOffset messageId userId -> ArrayWithOffset messageId userId
--set messageId message { offset, array, size } =
--    let
--        index =
--            Id.toInt messageId
--    in
--    if index < 0 || index >= size then
--        { offset = offset, array = array, size = size }
--
--    else
--        let
--            index2 =
--                index - offset
--        in
--
--        Array.set index2 (MessageLoaded message) array
