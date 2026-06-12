module SnapshotViewer exposing (main)

{-| Browser-based viewer for the visual snapshot test results produced by
run-snapshot-test.sh.

Served by view-snapshots.js, which exposes:

  - /manifest.json — which snapshots exist in the baseline/current/diff folders
  - /images/baseline/<name>, /images/current/<name>, /images/diff/<name>

Changed snapshots are listed first, with the odiff mask overlaid on the
current image so you can see where the change happened in context. Click any
image to open the raw PNG in a new tab.

-}

import Browser exposing (Document)
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Http
import Json.Decode exposing (Decoder)
import Url.Builder


main : Program () Model Msg
main =
    Browser.document
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type alias Manifest =
    { baselineName : String
    , snapshots : List SnapshotEntry
    }


type alias SnapshotEntry =
    { name : String
    , inBaseline : Bool
    , inCurrent : Bool
    , hasDiff : Bool
    }


type Status
    = Changed
    | Added
    | Removed
    | Unchanged


type Model
    = Loading
    | LoadFailed Http.Error
    | Loaded LoadedModel


type alias LoadedModel =
    { manifest : Manifest
    , showUnchanged : Bool
    , imageWidth : Int
    }


type Msg
    = GotManifest (Result Http.Error Manifest)
    | ToggledShowUnchanged Bool
    | ChangedImageWidth String


init : ( Model, Cmd Msg )
init =
    ( Loading
    , Http.get
        { url = "/manifest.json"
        , expect = Http.expectJson GotManifest decodeManifest
        }
    )


decodeManifest : Decoder Manifest
decodeManifest =
    Json.Decode.map2 Manifest
        (Json.Decode.field "baselineName" Json.Decode.string)
        (Json.Decode.field "snapshots" (Json.Decode.list decodeSnapshotEntry))


decodeSnapshotEntry : Decoder SnapshotEntry
decodeSnapshotEntry =
    Json.Decode.map4 SnapshotEntry
        (Json.Decode.field "name" Json.Decode.string)
        (Json.Decode.field "inBaseline" Json.Decode.bool)
        (Json.Decode.field "inCurrent" Json.Decode.bool)
        (Json.Decode.field "hasDiff" Json.Decode.bool)


status : SnapshotEntry -> Status
status entry =
    if entry.hasDiff then
        Changed

    else if entry.inCurrent && not entry.inBaseline then
        Added

    else if entry.inBaseline && not entry.inCurrent then
        Removed

    else
        Unchanged


statusOrder : Status -> Int
statusOrder value =
    case value of
        Changed ->
            0

        Added ->
            1

        Removed ->
            2

        Unchanged ->
            3


statusText : Status -> String
statusText value =
    case value of
        Changed ->
            "changed"

        Added ->
            "added (no baseline)"

        Removed ->
            "removed (only in baseline)"

        Unchanged ->
            "unchanged"


statusColor : Status -> String
statusColor value =
    case value of
        Changed ->
            "#b45309"

        Added ->
            "#15803d"

        Removed ->
            "#b91c1c"

        Unchanged ->
            "#52525b"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotManifest (Ok manifest) ->
            ( Loaded
                { manifest = manifest

                -- If nothing differs there is nothing else to look at, so
                -- start with the unchanged snapshots visible.
                , showUnchanged = List.all (\entry -> status entry == Unchanged) manifest.snapshots
                , imageWidth = 400
                }
            , Cmd.none
            )

        GotManifest (Err error) ->
            ( LoadFailed error, Cmd.none )

        ToggledShowUnchanged showUnchanged ->
            case model of
                Loaded loaded ->
                    ( Loaded { loaded | showUnchanged = showUnchanged }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        ChangedImageWidth text ->
            case ( model, String.toInt text ) of
                ( Loaded loaded, Just imageWidth ) ->
                    ( Loaded { loaded | imageWidth = imageWidth }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


view : Model -> Document Msg
view model =
    { title = "Snapshot viewer"
    , body =
        [ Html.div
            [ Html.Attributes.style "font-family" "system-ui, sans-serif"
            , Html.Attributes.style "background" "#18181b"
            , Html.Attributes.style "color" "#e4e4e7"
            , Html.Attributes.style "min-height" "100vh"
            ]
            [ case model of
                Loading ->
                    viewMessage "Loading manifest..."

                LoadFailed error ->
                    viewMessage ("Failed to load /manifest.json: " ++ httpErrorToString error)

                Loaded loaded ->
                    viewLoaded loaded
            ]
        ]
    }


viewMessage : String -> Html msg
viewMessage text =
    Html.div [ Html.Attributes.style "padding" "32px" ] [ Html.text text ]


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "bad url " ++ url

        Http.Timeout ->
            "timeout"

        Http.NetworkError ->
            "network error"

        Http.BadStatus code ->
            "status " ++ String.fromInt code

        Http.BadBody message ->
            "unexpected body: " ++ message


viewLoaded : LoadedModel -> Html Msg
viewLoaded { manifest, showUnchanged, imageWidth } =
    let
        visible =
            manifest.snapshots
                |> List.filter (\entry -> showUnchanged || status entry /= Unchanged)
                |> List.sortBy (\entry -> ( statusOrder (status entry), entry.name ))
    in
    Html.div []
        [ viewHeader manifest showUnchanged imageWidth
        , if List.isEmpty visible then
            viewMessage
                (if List.isEmpty manifest.snapshots then
                    "No snapshots found. Run ./run-snapshot-test.sh first."

                 else
                    "All snapshots match the baseline. Tick \"Show unchanged\" to see them anyway."
                )

          else
            Html.div
                [ Html.Attributes.style "padding" "16px" ]
                (List.map (viewSnapshot imageWidth) visible)
        ]


viewHeader : Manifest -> Bool -> Int -> Html Msg
viewHeader manifest showUnchanged imageWidth =
    Html.div
        [ Html.Attributes.style "position" "sticky"
        , Html.Attributes.style "top" "0"
        , Html.Attributes.style "z-index" "1"
        , Html.Attributes.style "background" "#27272a"
        , Html.Attributes.style "border-bottom" "1px solid #3f3f46"
        , Html.Attributes.style "padding" "12px 16px"
        , Html.Attributes.style "display" "flex"
        , Html.Attributes.style "flex-wrap" "wrap"
        , Html.Attributes.style "align-items" "center"
        , Html.Attributes.style "gap" "24px"
        ]
        [ Html.div
            [ Html.Attributes.style "font-weight" "700" ]
            [ Html.text "Visual snapshots" ]
        , Html.div
            [ Html.Attributes.style "color" "#a1a1aa" ]
            [ Html.text ("current vs " ++ manifest.baselineName) ]
        , Html.div [] [ Html.text (countsText manifest.snapshots) ]
        , Html.label
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-items" "center"
            , Html.Attributes.style "gap" "6px"
            , Html.Attributes.style "cursor" "pointer"
            ]
            [ Html.input
                [ Html.Attributes.type_ "checkbox"
                , Html.Attributes.checked showUnchanged
                , Html.Events.onCheck ToggledShowUnchanged
                ]
                []
            , Html.text "Show unchanged"
            ]
        , Html.label
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-items" "center"
            , Html.Attributes.style "gap" "6px"
            ]
            [ Html.text ("Image width " ++ String.fromInt imageWidth ++ "px")
            , Html.input
                [ Html.Attributes.type_ "range"
                , Html.Attributes.min "150"
                , Html.Attributes.max "1200"
                , Html.Attributes.step "50"
                , Html.Attributes.value (String.fromInt imageWidth)
                , Html.Events.onInput ChangedImageWidth
                ]
                []
            ]
        ]


countsText : List SnapshotEntry -> String
countsText snapshots =
    let
        count value =
            List.filter (\entry -> status entry == value) snapshots
                |> List.length
                |> String.fromInt
    in
    count Changed
        ++ " changed · "
        ++ count Added
        ++ " added · "
        ++ count Removed
        ++ " removed · "
        ++ count Unchanged
        ++ " unchanged"


viewSnapshot : Int -> SnapshotEntry -> Html msg
viewSnapshot imageWidth entry =
    Html.div
        [ Html.Attributes.style "background" "#27272a"
        , Html.Attributes.style "border" "1px solid #3f3f46"
        , Html.Attributes.style "border-radius" "8px"
        , Html.Attributes.style "padding" "12px 16px 16px 16px"
        , Html.Attributes.style "margin-bottom" "16px"
        ]
        [ Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-items" "baseline"
            , Html.Attributes.style "gap" "12px"
            , Html.Attributes.style "margin-bottom" "10px"
            ]
            [ Html.div
                [ Html.Attributes.style "font-weight" "600" ]
                [ Html.text entry.name ]
            , viewBadge (status entry)
            ]
        , Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "flex-wrap" "wrap"
            , Html.Attributes.style "gap" "16px"
            , Html.Attributes.style "align-items" "flex-start"
            ]
            [ viewColumn "Baseline"
                imageWidth
                (if entry.inBaseline then
                    Just (viewImageLink imageWidth (imageUrl "baseline" entry.name))

                 else
                    Nothing
                )
            , viewColumn "Current"
                imageWidth
                (if entry.inCurrent then
                    Just (viewImageLink imageWidth (imageUrl "current" entry.name))

                 else
                    Nothing
                )
            , viewColumn "Diff"
                imageWidth
                (if entry.hasDiff then
                    Just (viewDiffOverlay imageWidth entry.name)

                 else
                    Nothing
                )
            ]
        ]


viewBadge : Status -> Html msg
viewBadge value =
    Html.div
        [ Html.Attributes.style "background" (statusColor value)
        , Html.Attributes.style "color" "#fafafa"
        , Html.Attributes.style "border-radius" "999px"
        , Html.Attributes.style "padding" "2px 10px"
        , Html.Attributes.style "font-size" "12px"
        ]
        [ Html.text (statusText value) ]


viewColumn : String -> Int -> Maybe (Html msg) -> Html msg
viewColumn label imageWidth maybeImage =
    Html.div
        [ Html.Attributes.style "width" (px imageWidth) ]
        [ Html.div
            [ Html.Attributes.style "color" "#a1a1aa"
            , Html.Attributes.style "font-size" "12px"
            , Html.Attributes.style "margin-bottom" "4px"
            ]
            [ Html.text label ]
        , case maybeImage of
            Just image ->
                image

            Nothing ->
                Html.div
                    [ Html.Attributes.style "border" "1px dashed #3f3f46"
                    , Html.Attributes.style "border-radius" "4px"
                    , Html.Attributes.style "color" "#52525b"
                    , Html.Attributes.style "padding" "24px 0"
                    , Html.Attributes.style "text-align" "center"
                    ]
                    [ Html.text "—" ]
        ]


viewImageLink : Int -> String -> Html msg
viewImageLink imageWidth url =
    Html.a
        [ Html.Attributes.href url
        , Html.Attributes.target "_blank"
        ]
        [ Html.img
            [ Html.Attributes.src url
            , Html.Attributes.style "width" (px imageWidth)
            , Html.Attributes.style "display" "block"
            , Html.Attributes.style "border" "1px solid #3f3f46"
            , Html.Attributes.style "border-radius" "4px"
            ]
            []
        ]


{-| The odiff mask (changed pixels only, transparent elsewhere) drawn on top of
the current image, so the change is visible in context. Clicking opens the raw
mask PNG.
-}
viewDiffOverlay : Int -> String -> Html msg
viewDiffOverlay imageWidth name =
    Html.a
        [ Html.Attributes.href (imageUrl "diff" name)
        , Html.Attributes.target "_blank"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "display" "block"
        , Html.Attributes.style "width" (px imageWidth)
        ]
        [ Html.img
            [ Html.Attributes.src (imageUrl "current" name)
            , Html.Attributes.style "width" "100%"
            , Html.Attributes.style "display" "block"
            , Html.Attributes.style "border" "1px solid #3f3f46"
            , Html.Attributes.style "border-radius" "4px"
            , Html.Attributes.style "opacity" "0.4"
            ]
            []
        , Html.img
            [ Html.Attributes.src (imageUrl "diff" name)
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "left" "0"
            , Html.Attributes.style "top" "0"
            , Html.Attributes.style "width" "100%"
            ]
            []
        ]


imageUrl : String -> String -> String
imageUrl folder name =
    Url.Builder.absolute [ "images", folder, name ] []


px : Int -> String
px value =
    String.fromInt value ++ "px"
