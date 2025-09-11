module VisibleMessages exposing
    ( VisibleMessages
    , empty
    , firstLoad
    , increment
    , init
    , loadOlder
    , pageSize
    , slice
    , startIsVisible
    )

import Array exposing (Array)
import Id exposing (Id)
import Message exposing (Message, MessageState)


type alias VisibleMessages messageId =
    { oldest : Id messageId, count : Int }


init : Bool -> { a | messages : Array (Message messageId) } -> VisibleMessages messageId
init preloadMessages channel =
    if preloadMessages then
        { oldest = Array.length channel.messages - pageSize - 1 |> max 0 |> Id.fromInt
        , count = pageSize
        }

    else
        empty


empty : VisibleMessages messageId
empty =
    { oldest = Id.fromInt 0, count = 0 }


increment : { a | messages : Array b } -> VisibleMessages messageId -> VisibleMessages messageId
increment channel visibleMessages =
    if Id.toInt visibleMessages.oldest + visibleMessages.count == Array.length channel.messages then
        { oldest = visibleMessages.oldest, count = visibleMessages.count + 1 }

    else
        visibleMessages


loadOlder : Id messageId -> VisibleMessages messageId -> VisibleMessages messageId
loadOlder previousOldestVisibleMessage visibleMessages =
    let
        oldestNext : Int
        oldestNext =
            Id.toInt previousOldestVisibleMessage - pageSize |> max 0
    in
    { oldest = Id.fromInt oldestNext
    , count = visibleMessages.count + (Id.toInt visibleMessages.oldest - oldestNext)
    }


firstLoad : { a | messages : Array b } -> VisibleMessages messageId
firstLoad channel =
    { oldest = Array.length channel.messages - pageSize |> max 0 |> Id.fromInt
    , count = pageSize
    }


slice :
    { a | visibleMessages : VisibleMessages messageId, messages : Array (MessageState messageId) }
    -> Array (MessageState messageId)
slice { visibleMessages, messages } =
    Array.slice
        (Id.toInt visibleMessages.oldest)
        (Id.toInt visibleMessages.oldest + visibleMessages.count)
        messages


startIsVisible : VisibleMessages messageId -> Bool
startIsVisible visibleMessages =
    Id.toInt visibleMessages.oldest <= 0


pageSize : number
pageSize =
    30
