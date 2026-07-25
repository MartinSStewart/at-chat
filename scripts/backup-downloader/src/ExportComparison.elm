module ExportComparison exposing (Difference(..), compareExports, differenceToString, oneWeek)

{-| Compares a channel export generated from the latest backup against the
reference export that was stored the first time we saw that channel.

Only messages that are older than the cutoff are checked. Recent messages are
still being edited, reacted to and replied to, so they're expected to differ
between two backups. Messages older than a week should be settled, so if one of
them changes it means the backup lost or corrupted data.

Thread messages are checked against the same cutoff as top level messages rather
than inheriting their parent's age, otherwise an old message with an active
thread would look like it changed every time someone replied to it.

-}

import Dict exposing (Dict)
import Iso8601
import Json.Decode
import SafeJson exposing (SafeJson(..))
import Time


oneWeek : Int
oneWeek =
    7 * 24 * 60 * 60 * 1000


type Difference
    = MessageMissing String
    | MessageChanged String SafeJson SafeJson


{-| `Err` means one of the two documents couldn't be understood at all, which is
a different (and worse) kind of problem than the two disagreeing about a message.
-}
compareExports : Time.Posix -> String -> String -> Result String (List Difference)
compareExports cutoff referenceExport newExport =
    case ( parseMessages "reference export" referenceExport, parseMessages "new export" newExport ) of
        ( Ok reference, Ok new ) ->
            Ok (compareMessages cutoff "message " reference new)

        ( Err error, _ ) ->
            Err error

        ( _, Err error ) ->
            Err error


differenceToString : Difference -> String
differenceToString difference =
    case difference of
        MessageMissing path ->
            path ++ " is in the reference export but missing from the backup"

        MessageChanged path reference new ->
            path
                ++ " changed\n    reference: "
                ++ SafeJson.toString 0 reference
                ++ "\n    backup:    "
                ++ SafeJson.toString 0 new


parseMessages : String -> String -> Result String (List SafeJson)
parseMessages name export =
    case Json.Decode.decodeString SafeJson.decoder export of
        Ok (JsonObject fields) ->
            case Dict.get "messages" fields of
                Just (JsonArray messages) ->
                    Ok messages

                _ ->
                    Err ("The " ++ name ++ " has no \"messages\" array")

        Ok _ ->
            Err ("The " ++ name ++ " is not a JSON object")

        Err error ->
            Err ("The " ++ name ++ " is not valid JSON: " ++ Json.Decode.errorToString error)


compareMessages : Time.Posix -> String -> List SafeJson -> List SafeJson -> List Difference
compareMessages cutoff path reference new =
    let
        newByIndex : Dict Int SafeJson
        newByIndex =
            byIndex new
    in
    List.concatMap
        (\referenceMessage ->
            let
                messagePath : String
                messagePath =
                    path
                        ++ (case messageIndex referenceMessage of
                                Just index ->
                                    String.fromInt index

                                Nothing ->
                                    "?"
                           )
            in
            case Maybe.andThen (\index -> Dict.get index newByIndex) (messageIndex referenceMessage) of
                Just newMessage ->
                    (if isOldEnough cutoff referenceMessage && withoutThread referenceMessage /= withoutThread newMessage then
                        [ MessageChanged messagePath (withoutThread referenceMessage) (withoutThread newMessage) ]

                     else
                        []
                    )
                        ++ compareMessages
                            cutoff
                            (messagePath ++ " thread message ")
                            (threadMessages referenceMessage)
                            (threadMessages newMessage)

                Nothing ->
                    -- A recent message going missing is fine to ignore (it might not
                    -- have existed yet when the backup was taken) but only if nothing
                    -- old was nested inside it.
                    if containsOldMessage cutoff referenceMessage then
                        [ MessageMissing messagePath ]

                    else
                        []
        )
        reference


byIndex : List SafeJson -> Dict Int SafeJson
byIndex messages =
    List.filterMap (\message -> Maybe.map (\index -> ( index, message )) (messageIndex message)) messages
        |> Dict.fromList


messageIndex : SafeJson -> Maybe Int
messageIndex message =
    case field "index" message of
        Just (JsonNumber index) ->
            Just (round index)

        _ ->
            Nothing


{-| `deletedAt` is the fallback because a deleted message is the one kind of
message that doesn't carry a `createdAt`.
-}
messageTime : SafeJson -> Maybe Time.Posix
messageTime message =
    List.filterMap
        (\key ->
            case field key message of
                Just (JsonString text) ->
                    Iso8601.toTime text |> Result.toMaybe

                _ ->
                    Nothing
        )
        [ "createdAt", "deletedAt" ]
        |> List.head


isOldEnough : Time.Posix -> SafeJson -> Bool
isOldEnough cutoff message =
    case messageTime message of
        Just time ->
            Time.posixToMillis time < Time.posixToMillis cutoff

        Nothing ->
            -- A message we can't date is checked anyway. Skipping it would let a
            -- corrupted timestamp hide every other change to that message.
            True


containsOldMessage : Time.Posix -> SafeJson -> Bool
containsOldMessage cutoff message =
    isOldEnough cutoff message
        || List.any (containsOldMessage cutoff) (threadMessages message)


threadMessages : SafeJson -> List SafeJson
threadMessages message =
    case field "threadMessages" message of
        Just (JsonArray messages) ->
            messages

        _ ->
            []


{-| Thread messages are compared separately, so they're removed before comparing
the message they hang off of.
-}
withoutThread : SafeJson -> SafeJson
withoutThread message =
    case message of
        JsonObject fields ->
            JsonObject (Dict.remove "threadMessages" fields)

        _ ->
            message


field : String -> SafeJson -> Maybe SafeJson
field key message =
    case message of
        JsonObject fields ->
            Dict.get key fields

        _ ->
            Nothing
