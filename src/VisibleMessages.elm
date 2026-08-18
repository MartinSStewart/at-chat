module VisibleMessages exposing
    ( VisibleMessages
    , empty
    , firstLoad
    , increment
    , init
    , isLoading
    , loadOlder
    , pageSize
    , slice
    , startIsVisible
    )

import Id exposing (Id)
import MessageArray exposing (MessageArray)


type alias VisibleMessages messageId =
    { oldest : Id messageId, count : Int, loadingMessages : Bool }


init : Bool -> Int -> VisibleMessages messageId
init preloadMessages messageCount =
    if preloadMessages then
        firstLoad messageCount

    else
        empty


empty : VisibleMessages messageId
empty =
    { oldest = Id.fromInt 0, count = 0, loadingMessages = False }


increment : Int -> VisibleMessages messageId -> VisibleMessages messageId
increment messageCount visibleMessages =
    if Id.toInt visibleMessages.oldest + visibleMessages.count == messageCount then
        { oldest = visibleMessages.oldest
        , count = visibleMessages.count + 1
        , loadingMessages = visibleMessages.loadingMessages
        }

    else
        visibleMessages


isLoading : VisibleMessages messageId -> VisibleMessages messageId
isLoading visibleMessages =
    { visibleMessages | loadingMessages = True }


loadOlder : Id messageId -> VisibleMessages messageId -> VisibleMessages messageId
loadOlder previousOldestVisibleMessage visibleMessages =
    let
        oldestNext : Int
        oldestNext =
            Id.toInt previousOldestVisibleMessage - pageSize |> max 0
    in
    { oldest = Id.fromInt oldestNext
    , count = visibleMessages.count + (Id.toInt visibleMessages.oldest - oldestNext)
    , loadingMessages = False
    }


firstLoad : Int -> VisibleMessages messageId
firstLoad messageCount =
    { oldest = messageCount - pageSize |> max 0 |> Id.fromInt
    , count = pageSize
    , loadingMessages = False
    }


slice :
    { a | visibleMessages : VisibleMessages messageId, messages : MessageArray messageId message }
    -> MessageArray messageId message
slice { visibleMessages, messages } =
    MessageArray.slice
        visibleMessages.oldest
        (Id.toInt visibleMessages.oldest + visibleMessages.count |> Id.fromInt)
        messages


{-| The oldest message being held is the first one ever written, so the view can show the
header saying the conversation starts here. A load that's still in flight counts as not
visible: `empty` starts out pointing at message 0, so a conversation waiting on its first
page would otherwise claim to be showing its own beginning, and a slow load would leave
someone looking at that header thinking there's nothing older.
-}
startIsVisible : VisibleMessages messageId -> Bool
startIsVisible visibleMessages =
    Id.toInt visibleMessages.oldest <= 0 && not visibleMessages.loadingMessages


pageSize : number
pageSize =
    30
