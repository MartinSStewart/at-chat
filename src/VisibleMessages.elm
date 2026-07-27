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

import Id exposing (Id)
import MessageArray exposing (MessageArray)


type alias VisibleMessages messageId =
    { oldest : Id messageId, count : Int }


init : Bool -> Int -> VisibleMessages messageId
init preloadMessages messageCount =
    if preloadMessages then
        firstLoad messageCount

    else
        empty


empty : VisibleMessages messageId
empty =
    { oldest = Id.fromInt 0, count = 0 }


increment : Int -> VisibleMessages messageId -> VisibleMessages messageId
increment messageCount visibleMessages =
    if Id.toInt visibleMessages.oldest + visibleMessages.count == messageCount then
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


firstLoad : Int -> VisibleMessages messageId
firstLoad messageCount =
    { oldest = messageCount - pageSize |> max 0 |> Id.fromInt
    , count = pageSize
    }


slice :
    { a | visibleMessages : VisibleMessages messageId, messages : MessageArray messageId message }
    -> MessageArray messageId message
slice { visibleMessages, messages } =
    MessageArray.slice
        visibleMessages.oldest
        (Id.toInt visibleMessages.oldest + visibleMessages.count |> Id.fromInt)
        messages


startIsVisible : VisibleMessages messageId -> Bool
startIsVisible visibleMessages =
    Id.toInt visibleMessages.oldest <= 0


pageSize : number
pageSize =
    30
