module VisibleMessages exposing
    ( PageRequest(..)
    , VisibleMessages
    , doneLoading
    , empty
    , firstLoad
    , increment
    , init
    , isLoading
    , loadNewer
    , loadOlder
    , maxCount
    , pageSize
    , reachesEnd
    , slice
    , startIsVisible
    , unloadHidden
    )

import Id exposing (Id)
import Message
import MessageArray exposing (MessageArray)


type alias VisibleMessages messageId =
    { oldest : Id messageId, count : Int, loadingMessages : Bool }


{-| A page of messages to load. `PageBefore` is the page that ends just before the given message,
`PageFrom` the page that starts at it.
-}
type PageRequest messageId
    = PageBefore (Id messageId)
    | PageFrom (Id messageId)


init : Bool -> Int -> VisibleMessages messageId
init preloadMessages messageCount =
    if preloadMessages then
        firstLoad messageCount

    else
        empty


empty : VisibleMessages messageId
empty =
    { oldest = Id.fromInt 0, count = 0, loadingMessages = False }


{-| A message was added after the `messageCount` that already existed. If the newest message
was visible then so is this one, which pushes the oldest message out once there are `maxCount`
of them.
-}
increment : Int -> VisibleMessages messageId -> VisibleMessages messageId
increment messageCount visibleMessages =
    if reachesEnd messageCount visibleMessages then
        let
            oldest : Int
            oldest =
                max (Id.toInt visibleMessages.oldest) (messageCount + 1 - maxCount)
        in
        { oldest = Id.fromInt oldest
        , count = messageCount + 1 - oldest
        , loadingMessages = visibleMessages.loadingMessages
        }

    else
        visibleMessages


{-| The newest message is visible (or there are no messages at all).
-}
reachesEnd : Int -> VisibleMessages messageId -> Bool
reachesEnd messageCount visibleMessages =
    Id.toInt visibleMessages.oldest + visibleMessages.count >= messageCount


isLoading : VisibleMessages messageId -> VisibleMessages messageId
isLoading visibleMessages =
    { visibleMessages | loadingMessages = True }


doneLoading : VisibleMessages messageId -> VisibleMessages messageId
doneLoading visibleMessages =
    { visibleMessages | loadingMessages = False }


loadOlder : Id messageId -> VisibleMessages messageId -> VisibleMessages messageId
loadOlder previousOldestVisibleMessage visibleMessages =
    let
        oldestNext : Int
        oldestNext =
            Id.toInt previousOldestVisibleMessage - pageSize |> max 0
    in
    { oldest = Id.fromInt oldestNext
    , count = visibleMessages.count + (Id.toInt visibleMessages.oldest - oldestNext) |> min maxCount
    , loadingMessages = False
    }


{-| The page of messages starting at `firstNewMessage` has been loaded. If that page carries on
from the newest visible message it's added on, pushing out the oldest messages once there are
more than `maxCount` of them. Otherwise it was a jump to somewhere else in the conversation and
that page is all that's visible.
-}
loadNewer : Int -> Id messageId -> VisibleMessages messageId -> VisibleMessages messageId
loadNewer messageCount firstNewMessage visibleMessages =
    let
        end : Int
        end =
            Id.toInt firstNewMessage + pageSize |> min messageCount

        oldest : Int
        oldest =
            if Id.toInt visibleMessages.oldest + visibleMessages.count == Id.toInt firstNewMessage then
                max (Id.toInt visibleMessages.oldest) (end - maxCount)

            else
                Id.toInt firstNewMessage
    in
    { oldest = Id.fromInt oldest
    , count = end - oldest |> max 0
    , loadingMessages = False
    }


{-| Unloads the messages that aren't visible, apart from the ones still needed elsewhere: the
newest message (previews of the conversation show it), the messages that visible messages
reply to, and `keep` (thread starters, for a channel).
-}
unloadHidden :
    List (Id messageId)
    -> { a | visibleMessages : VisibleMessages messageId, messages : MessageArray messageId userId channelId }
    -> { a | visibleMessages : VisibleMessages messageId, messages : MessageArray messageId userId channelId }
unloadHidden keep channel =
    let
        visible : MessageArray messageId userId channelId
        visible =
            slice channel

        keep2 : List (Id messageId)
        keep2 =
            (MessageArray.length channel.messages - 1 |> Id.fromInt)
                :: MessageArray.foldr
                    (\_ maybeMessage list ->
                        case Maybe.andThen Message.repliedToMessage maybeMessage of
                            Just repliedTo ->
                                repliedTo :: list

                            Nothing ->
                                list
                    )
                    keep
                    visible
    in
    { channel
        | messages =
            MessageArray.unloadOutside
                channel.visibleMessages.oldest
                (Id.toInt channel.visibleMessages.oldest + channel.visibleMessages.count |> Id.fromInt)
                channel.messages
                |> MessageArray.setMany
                    (List.filterMap
                        (\id -> MessageArray.get id channel.messages |> Maybe.map (Tuple.pair id))
                        keep2
                    )
    }


firstLoad : Int -> VisibleMessages messageId
firstLoad messageCount =
    let
        oldest : Int
        oldest =
            messageCount - pageSize |> max 0
    in
    { oldest = Id.fromInt oldest
    , count = messageCount - oldest
    , loadingMessages = False
    }


slice :
    { a | visibleMessages : VisibleMessages messageId, messages : MessageArray messageId message channelId }
    -> MessageArray messageId message channelId
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


{-| The most messages a conversation keeps visible, and so loaded, at once.
-}
maxCount : number
maxCount =
    pageSize * 3
