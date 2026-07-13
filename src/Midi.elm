module Midi exposing
    ( Byte
    , Channel
    , MidiEvent(..)
    , MidiMessage
    , MidiRecording(..)
    , Note
    , SysExFlavour(..)
    , Ticks
    , Track
    , TracksType(..)
    , Velocity
    , eox
    , eventFromBytes
    , eventToBytes
    , fromBytes
    , main
    , toBytes
    , validRecording
    )

{-| A self-contained MIDI file parser and renderer.

The types and parsing behavior are modelled on newlandsvalley/elm-comidi
(Elm 0.18), updated to Elm 0.19 and rewritten on top of elm/bytes instead of
String-based parser combinators.

Run `lamdera reactor` (or `elm reactor`) and open
<http://localhost:8000/src/Midi.elm> to try it: it renders a built-in demo
recording and lets you open any `.mid` file from disk, showing a piano roll
and the decoded event list.

-}

import Bitwise
import Browser
import Bytes exposing (Bytes)
import Bytes.Decode as Decode exposing (Decoder, Step(..))
import Bytes.Encode as Encode exposing (Encoder)
import Dict exposing (Dict)
import File exposing (File)
import File.Select
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Svg
import Svg.Attributes
import Task



-- TYPES


{-| Elapsed time, in MIDI ticks
-}
type alias Ticks =
    Int


{-| A hint that we're really interested in bytes in some MidiEvent
constructors that hold Lists of Ints
-}
type alias Byte =
    Int


type alias Channel =
    Int


type alias Note =
    Int


type alias Velocity =
    Int


{-| Discriminates between the two forms of SysEx event as characterised by the
lead-in byte: 0xF0 (normal) or 0xF7 (escaped).
-}
type SysExFlavour
    = F0
    | F7


{-| A MIDI event. Running status messages don't appear here because the parser
expands them into the underlying channel messages.
-}
type MidiEvent
    = -- meta messages
      SequenceNumber Int
    | Text String
    | Copyright String
    | TrackName String
    | InstrumentName String
    | Lyrics String
    | Marker String
    | CuePoint String
    | ChannelPrefix Int
    | Tempo Int
    | SMPTEOffset Int Int Int Int Int
    | TimeSignature Int Int Int Int
    | KeySignature Int Int
    | SequencerSpecific (List Byte)
    | SysEx SysExFlavour (List Byte)
    | Unspecified Int (List Byte)
      -- channel messages
    | NoteOn Channel Note Velocity
    | NoteOff Channel Note Velocity
    | NoteAfterTouch Channel Note Velocity
    | ControlChange Channel Int Int
    | ProgramChange Channel Int
    | ChannelAfterTouch Channel Velocity
    | PitchBend Channel Int


type alias MidiMessage =
    ( Ticks, MidiEvent )


type alias Track =
    List MidiMessage


{-| Are the tracks in a multi-track recording played simultaneously (format 1)
or independently (format 2)?
-}
type TracksType
    = Simultaneous
    | Independent


type MidiRecording
    = SingleTrack Int Track
    | MultipleTracks TracksType Int (List Track)


{-| The End Of eXclusive byte that terminates a SysEx message
-}
eox : Int
eox =
    0xF7


{-| A MidiRecording is valid if all multipart SysEx messages are terminated
and nothing is interleaved between their parts.
-}
validRecording : MidiRecording -> Bool
validRecording recording =
    let
        endsWithEox data =
            case List.reverse data of
                last :: _ ->
                    last == eox

                [] ->
                    False

        validTrack multipart track =
            case track of
                -- all multipart messages must be finished
                [] ->
                    not multipart

                ( _, event ) :: rest ->
                    case ( event, multipart ) of
                        ( SysEx F0 data, False ) ->
                            validTrack (not (endsWithEox data)) rest

                        -- after the first packet, all parts of a multipart
                        -- message must start with F7
                        ( SysEx F0 _, True ) ->
                            False

                        ( SysEx F7 data, True ) ->
                            validTrack (not (endsWithEox data)) rest

                        ( SysEx F7 _, False ) ->
                            validTrack multipart rest

                        -- no other events are allowed in between the packets
                        -- of a multipart SysEx message
                        ( _, True ) ->
                            False

                        _ ->
                            validTrack multipart rest
    in
    case recording of
        SingleTrack _ track ->
            validTrack False track

        MultipleTracks _ _ tracks ->
            List.all (validTrack False) tracks



-- PARSING


{-| Parse a MIDI file image
-}
fromBytes : Bytes -> Result String MidiRecording
fromBytes data =
    case Decode.decode recordingDecoder data of
        Just recording ->
            Ok recording

        Nothing ->
            if Decode.decode (Decode.string 4) data == Just "MThd" then
                Err "Found a MIDI header but failed to parse the rest of the file."

            else
                Err "This doesn't look like a MIDI file (the MThd header is missing)."


{-| Parse a single standalone MIDI event (as found in Web MIDI, not in a MIDI
file): SysEx events are introduced by 0xF0 and terminated by the EOX byte
rather than being length-prefixed, and running status isn't supported.
-}
eventFromBytes : Bytes -> Result String MidiEvent
eventFromBytes data =
    case Decode.decode standaloneEventDecoder data of
        Just event ->
            Ok event

        Nothing ->
            Err "Failed to parse MIDI event."


type alias Header =
    { format : Int
    , trackCount : Int
    , ticksPerBeat : Int
    }


recordingDecoder : Decoder MidiRecording
recordingDecoder =
    headerDecoder |> Decode.andThen tracksDecoder


headerDecoder : Decoder Header
headerDecoder =
    magicDecoder "MThd" uint32
        |> Decode.andThen
            (\chunkSize ->
                if chunkSize < 6 then
                    Decode.fail

                else
                    Decode.map3 Header uint16 uint16 uint16
                        -- quietly eat any extra bytes in a non-standard size chunk
                        |> skipping (Decode.bytes (chunkSize - 6))
            )


tracksDecoder : Header -> Decoder MidiRecording
tracksDecoder header =
    case header.format of
        0 ->
            if header.trackCount == 1 then
                Decode.map (SingleTrack header.ticksPerBeat) trackDecoder

            else
                Decode.fail

        1 ->
            Decode.map (MultipleTracks Simultaneous header.ticksPerBeat)
                (repeatDecoder header.trackCount trackDecoder)

        2 ->
            Decode.map (MultipleTracks Independent header.ticksPerBeat)
                (repeatDecoder header.trackCount trackDecoder)

        _ ->
            Decode.fail


trackDecoder : Decoder Track
trackDecoder =
    magicDecoder "MTrk" uint32
        -- rely on the end-of-track event rather than the chunk length
        |> Decode.andThen (\_ -> messagesDecoder)


messagesDecoder : Decoder (List MidiMessage)
messagesDecoder =
    Decode.loop ( Nothing, [] ) messagesStep


messagesStep :
    ( Maybe Int, List MidiMessage )
    -> Decoder (Step ( Maybe Int, List MidiMessage ) (List MidiMessage))
messagesStep ( runningStatus, acc ) =
    varInt
        |> Decode.andThen
            (\ticks ->
                fileEventDecoder runningStatus
                    |> Decode.map
                        (\fileEvent ->
                            case fileEvent of
                                FileEvent event newStatus ->
                                    Loop ( newStatus, ( ticks, event ) :: acc )

                                EndOfTrack ->
                                    Done (List.reverse acc)
                        )
            )


type FileEvent
    = -- an event plus the running status that now applies
      FileEvent MidiEvent (Maybe Int)
    | EndOfTrack


fileEventDecoder : Maybe Int -> Decoder FileEvent
fileEventDecoder runningStatus =
    Decode.unsignedInt8
        |> Decode.andThen
            (\byte ->
                if byte < 0x80 then
                    -- running status: reuse the previous channel status byte,
                    -- with this byte as the first data byte
                    case runningStatus of
                        Just status ->
                            channelEventDecoder status byte
                                |> Decode.map (\event -> FileEvent event runningStatus)

                        Nothing ->
                            Decode.fail

                else if byte < 0xF0 then
                    Decode.unsignedInt8
                        |> Decode.andThen (channelEventDecoder byte)
                        |> Decode.map (\event -> FileEvent event (Just byte))

                else if byte == 0xF0 then
                    -- SysEx and meta events cancel running status
                    Decode.map (\bytes -> FileEvent (SysEx F0 bytes) Nothing) sysExBodyDecoder

                else if byte == eox then
                    Decode.map (\bytes -> FileEvent (SysEx F7 bytes) Nothing) sysExBodyDecoder

                else if byte == 0xFF then
                    metaEventDecoder

                else
                    Decode.fail
            )


{-| Decode a channel event whose status byte and first data byte have already
been consumed.
-}
channelEventDecoder : Int -> Int -> Decoder MidiEvent
channelEventDecoder status data1 =
    let
        channel =
            Bitwise.and 0x0F status
    in
    case Bitwise.and 0xF0 status of
        0x80 ->
            Decode.map (NoteOff channel data1) Decode.unsignedInt8

        0x90 ->
            Decode.map
                (\velocity ->
                    -- NoteOn with velocity zero means NoteOff
                    if velocity == 0 then
                        NoteOff channel data1 0

                    else
                        NoteOn channel data1 velocity
                )
                Decode.unsignedInt8

        0xA0 ->
            Decode.map (NoteAfterTouch channel data1) Decode.unsignedInt8

        0xB0 ->
            Decode.map (ControlChange channel data1) Decode.unsignedInt8

        0xC0 ->
            Decode.succeed (ProgramChange channel data1)

        0xD0 ->
            Decode.succeed (ChannelAfterTouch channel data1)

        0xE0 ->
            Decode.map
                (\msb -> PitchBend channel (data1 + Bitwise.shiftLeftBy 7 msb))
                Decode.unsignedInt8

        _ ->
            Decode.fail


{-| The length-prefixed body of a SysEx event as found in a MIDI file
-}
sysExBodyDecoder : Decoder (List Byte)
sysExBodyDecoder =
    varInt |> Decode.andThen (\length -> repeatDecoder length Decode.unsignedInt8)


{-| Decode a meta event (the 0xFF lead-in byte has already been consumed)
-}
metaEventDecoder : Decoder FileEvent
metaEventDecoder =
    Decode.unsignedInt8
        |> Decode.andThen
            (\metaType ->
                varInt
                    |> Decode.andThen (\length -> repeatDecoder length Decode.unsignedInt8)
                    |> Decode.map
                        (\payload ->
                            if metaType == 0x2F then
                                EndOfTrack

                            else
                                FileEvent (buildMetaEvent metaType payload) Nothing
                        )
            )


{-| Interpret a meta event payload. Known event types with a malformed payload
are kept as Unspecified rather than failing the whole parse.
-}
buildMetaEvent : Int -> List Byte -> MidiEvent
buildMetaEvent metaType payload =
    let
        asString =
            String.fromList (List.map Char.fromCode payload)
    in
    case ( metaType, payload ) of
        ( 0x00, [ a, b ] ) ->
            SequenceNumber (Bitwise.shiftLeftBy 8 a + b)

        ( 0x01, _ ) ->
            Text asString

        ( 0x02, _ ) ->
            Copyright asString

        ( 0x03, _ ) ->
            TrackName asString

        ( 0x04, _ ) ->
            InstrumentName asString

        ( 0x05, _ ) ->
            Lyrics asString

        ( 0x06, _ ) ->
            Marker asString

        ( 0x07, _ ) ->
            CuePoint asString

        ( 0x20, [ channel ] ) ->
            ChannelPrefix channel

        ( 0x51, [ a, b, c ] ) ->
            Tempo (Bitwise.shiftLeftBy 16 a + Bitwise.shiftLeftBy 8 b + c)

        ( 0x54, [ hour, minute, second, frame, frameFraction ] ) ->
            SMPTEOffset hour minute second frame frameFraction

        ( 0x58, [ numerator, denominatorExponent, clocks, thirtySeconds ] ) ->
            TimeSignature numerator (2 ^ denominatorExponent) clocks thirtySeconds

        ( 0x59, [ accidentals, mode ] ) ->
            KeySignature (toSignedInt8 accidentals) mode

        ( 0x7F, _ ) ->
            SequencerSpecific payload

        _ ->
            Unspecified metaType payload


standaloneEventDecoder : Decoder MidiEvent
standaloneEventDecoder =
    Decode.unsignedInt8
        |> Decode.andThen
            (\byte ->
                if byte >= 0x80 && byte < 0xF0 then
                    Decode.unsignedInt8 |> Decode.andThen (channelEventDecoder byte)

                else if byte == 0xF0 then
                    -- data bytes up to (but not including) the EOX terminator
                    Decode.loop []
                        (\acc ->
                            Decode.unsignedInt8
                                |> Decode.map
                                    (\b ->
                                        if b == eox then
                                            Done (List.reverse acc)

                                        else
                                            Loop (b :: acc)
                                    )
                        )
                        |> Decode.map (SysEx F0)

                else if byte == 0xFF then
                    metaEventDecoder
                        |> Decode.andThen
                            (\fileEvent ->
                                case fileEvent of
                                    FileEvent event _ ->
                                        Decode.succeed event

                                    EndOfTrack ->
                                        Decode.fail
                            )

                else
                    Decode.fail
            )



-- PARSING HELPERS


uint16 : Decoder Int
uint16 =
    Decode.unsignedInt16 Bytes.BE


uint32 : Decoder Int
uint32 =
    Decode.unsignedInt32 Bytes.BE


{-| A variable length integer: 7 bits per byte, high bit set on all bytes
except the last, most significant byte first.
-}
varInt : Decoder Int
varInt =
    Decode.loop 0
        (\acc ->
            Decode.unsignedInt8
                |> Decode.map
                    (\byte ->
                        if byte < 0x80 then
                            Done (Bitwise.shiftLeftBy 7 acc + byte)

                        else
                            Loop (Bitwise.shiftLeftBy 7 acc + Bitwise.and 0x7F byte)
                    )
        )


toSignedInt8 : Int -> Int
toSignedInt8 byte =
    if byte > 127 then
        byte - 256

    else
        byte


{-| Expect the given chunk tag, then continue with the given decoder
-}
magicDecoder : String -> Decoder a -> Decoder a
magicDecoder expected decoder =
    Decode.string (String.length expected)
        |> Decode.andThen
            (\actual ->
                if actual == expected then
                    decoder

                else
                    Decode.fail
            )


{-| Run a decoder, then run (and throw away) another one
-}
skipping : Decoder ignored -> Decoder a -> Decoder a
skipping ignored decoder =
    decoder |> Decode.andThen (\value -> Decode.map (\_ -> value) ignored)


repeatDecoder : Int -> Decoder a -> Decoder (List a)
repeatDecoder count decoder =
    Decode.loop ( count, [] )
        (\( remaining, acc ) ->
            if remaining <= 0 then
                Decode.succeed (Done (List.reverse acc))

            else
                Decode.map (\item -> Loop ( remaining - 1, item :: acc )) decoder
        )



-- ENCODING


{-| Encode a MIDI recording as a MIDI file image
-}
toBytes : MidiRecording -> Bytes
toBytes recording =
    Encode.encode (recordingEncoder recording)


{-| Encode a single standalone MIDI event (the counterpart of eventFromBytes)
-}
eventToBytes : MidiEvent -> Bytes
eventToBytes event =
    Encode.encode (byteListEncoder (standaloneEventBytes event))


recordingEncoder : MidiRecording -> Encoder
recordingEncoder recording =
    case recording of
        SingleTrack ticksPerBeat track ->
            Encode.sequence [ headerEncoder 0 1 ticksPerBeat, trackEncoder track ]

        MultipleTracks tracksType ticksPerBeat tracks ->
            let
                format =
                    case tracksType of
                        Simultaneous ->
                            1

                        Independent ->
                            2
            in
            Encode.sequence
                (headerEncoder format (List.length tracks) ticksPerBeat
                    :: List.map trackEncoder tracks
                )


headerEncoder : Int -> Int -> Int -> Encoder
headerEncoder format trackCount ticksPerBeat =
    Encode.sequence
        [ Encode.string "MThd"
        , Encode.unsignedInt32 Bytes.BE 6
        , Encode.unsignedInt16 Bytes.BE format
        , Encode.unsignedInt16 Bytes.BE trackCount
        , Encode.unsignedInt16 Bytes.BE ticksPerBeat
        ]


trackEncoder : Track -> Encoder
trackEncoder track =
    let
        endOfTrack =
            [ 0x00, 0xFF, 0x2F, 0x00 ]

        body =
            Encode.encode
                (Encode.sequence
                    (List.map messageEncoder track ++ [ byteListEncoder endOfTrack ])
                )
    in
    Encode.sequence
        [ Encode.string "MTrk"
        , Encode.unsignedInt32 Bytes.BE (Bytes.width body)
        , Encode.bytes body
        ]


messageEncoder : MidiMessage -> Encoder
messageEncoder ( ticks, event ) =
    byteListEncoder (varIntBytes ticks ++ fileEventBytes event)


fileEventBytes : MidiEvent -> List Byte
fileEventBytes event =
    case event of
        -- in a file, SysEx events are length-prefixed
        SysEx F0 bytes ->
            0xF0 :: varIntBytes (List.length bytes) ++ bytes

        SysEx F7 bytes ->
            eox :: varIntBytes (List.length bytes) ++ bytes

        _ ->
            standaloneEventBytes event


standaloneEventBytes : MidiEvent -> List Byte
standaloneEventBytes event =
    case event of
        SequenceNumber value ->
            metaBytes 0x00 [ Bitwise.shiftRightBy 8 value, Bitwise.and 0xFF value ]

        Text text ->
            metaBytes 0x01 (stringBytes text)

        Copyright text ->
            metaBytes 0x02 (stringBytes text)

        TrackName text ->
            metaBytes 0x03 (stringBytes text)

        InstrumentName text ->
            metaBytes 0x04 (stringBytes text)

        Lyrics text ->
            metaBytes 0x05 (stringBytes text)

        Marker text ->
            metaBytes 0x06 (stringBytes text)

        CuePoint text ->
            metaBytes 0x07 (stringBytes text)

        ChannelPrefix channel ->
            metaBytes 0x20 [ channel ]

        Tempo tempo ->
            metaBytes 0x51
                [ Bitwise.and 0xFF (Bitwise.shiftRightBy 16 tempo)
                , Bitwise.and 0xFF (Bitwise.shiftRightBy 8 tempo)
                , Bitwise.and 0xFF tempo
                ]

        SMPTEOffset hour minute second frame frameFraction ->
            metaBytes 0x54 [ hour, minute, second, frame, frameFraction ]

        TimeSignature numerator denominator clocks thirtySeconds ->
            metaBytes 0x58 [ numerator, log2 denominator, clocks, thirtySeconds ]

        KeySignature accidentals mode ->
            metaBytes 0x59 [ Bitwise.and 0xFF accidentals, mode ]

        SequencerSpecific bytes ->
            metaBytes 0x7F bytes

        Unspecified metaType bytes ->
            metaBytes metaType bytes

        -- as a standalone event, a SysEx message is terminated by EOX
        SysEx F0 bytes ->
            0xF0 :: bytes ++ [ eox ]

        -- escaped SysEx only really makes sense inside a MIDI file
        SysEx F7 bytes ->
            eox :: bytes

        NoteOn channel note velocity ->
            [ 0x90 + channel, note, velocity ]

        NoteOff channel note velocity ->
            [ 0x80 + channel, note, velocity ]

        NoteAfterTouch channel note velocity ->
            [ 0xA0 + channel, note, velocity ]

        ControlChange channel controllerNumber value ->
            [ 0xB0 + channel, controllerNumber, value ]

        ProgramChange channel value ->
            [ 0xC0 + channel, value ]

        ChannelAfterTouch channel velocity ->
            [ 0xD0 + channel, velocity ]

        PitchBend channel bend ->
            [ 0xE0 + channel, Bitwise.and 0x7F bend, Bitwise.shiftRightBy 7 bend ]


metaBytes : Int -> List Byte -> List Byte
metaBytes metaType payload =
    0xFF :: metaType :: varIntBytes (List.length payload) ++ payload


varIntBytes : Int -> List Byte
varIntBytes value =
    let
        go remaining acc =
            if remaining <= 0 then
                acc

            else
                go (Bitwise.shiftRightBy 7 remaining)
                    (Bitwise.or 0x80 (Bitwise.and 0x7F remaining) :: acc)
    in
    go (Bitwise.shiftRightBy 7 value) [ Bitwise.and 0x7F value ]


stringBytes : String -> List Byte
stringBytes text =
    List.map (Char.toCode >> Bitwise.and 0xFF) (String.toList text)


log2 : Int -> Int
log2 value =
    if value <= 1 then
        0

    else
        1 + log2 (value // 2)


byteListEncoder : List Byte -> Encoder
byteListEncoder bytes =
    Encode.sequence (List.map Encode.unsignedInt8 bytes)



-- RENDERING


type alias PianoNote =
    { trackIndex : Int
    , channel : Channel
    , note : Note
    , velocity : Velocity
    , start : Ticks
    , duration : Ticks
    }


tracksOf : MidiRecording -> List Track
tracksOf recording =
    case recording of
        SingleTrack _ track ->
            [ track ]

        MultipleTracks _ _ tracks ->
            tracks


ticksPerBeatOf : MidiRecording -> Int
ticksPerBeatOf recording =
    case recording of
        SingleTrack ticksPerBeat _ ->
            ticksPerBeat

        MultipleTracks _ ticksPerBeat _ ->
            ticksPerBeat


{-| Pair up NoteOn/NoteOff events into notes with a start time and duration
-}
extractNotes : MidiRecording -> { notes : List PianoNote, totalTicks : Ticks }
extractNotes recording =
    let
        perTrack =
            List.indexedMap notesFromTrack (tracksOf recording)
    in
    { notes = List.concatMap .notes perTrack
    , totalTicks = List.maximum (List.map .endTime perTrack) |> Maybe.withDefault 0
    }


notesFromTrack : Int -> Track -> { notes : List PianoNote, endTime : Ticks }
notesFromTrack trackIndex track =
    let
        step ( deltaTicks, event ) state =
            let
                time =
                    state.time + deltaTicks
            in
            case event of
                NoteOn channel note velocity ->
                    if velocity == 0 then
                        closeNote trackIndex channel note time { state | time = time }

                    else
                        { state
                            | time = time
                            , active =
                                Dict.update (noteKey channel note)
                                    (\stack -> Just (( time, velocity ) :: Maybe.withDefault [] stack))
                                    state.active
                        }

                NoteOff channel note _ ->
                    closeNote trackIndex channel note time { state | time = time }

                _ ->
                    { state | time = time }

        result =
            List.foldl step { time = 0, active = Dict.empty, notes = [] } track

        -- treat notes that never got a NoteOff as lasting until the end of the track
        unterminated =
            Dict.toList result.active
                |> List.concatMap
                    (\( key, stack ) ->
                        List.map
                            (\( start, velocity ) ->
                                { trackIndex = trackIndex
                                , channel = key // 128
                                , note = modBy 128 key
                                , velocity = velocity
                                , start = start
                                , duration = result.time - start
                                }
                            )
                            stack
                    )
    in
    { notes = List.reverse result.notes ++ unterminated, endTime = result.time }


noteKey : Channel -> Note -> Int
noteKey channel note =
    channel * 128 + note


closeNote :
    Int
    -> Channel
    -> Note
    -> Ticks
    ->
        { time : Ticks
        , active : Dict Int (List ( Ticks, Velocity ))
        , notes : List PianoNote
        }
    ->
        { time : Ticks
        , active : Dict Int (List ( Ticks, Velocity ))
        , notes : List PianoNote
        }
closeNote trackIndex channel note time state =
    case Dict.get (noteKey channel note) state.active of
        Just (( start, velocity ) :: rest) ->
            { state
                | active =
                    Dict.insert (noteKey channel note)
                        rest
                        state.active
                , notes =
                    { trackIndex = trackIndex
                    , channel = channel
                    , note = note
                    , velocity = velocity
                    , start = start
                    , duration = time - start
                    }
                        :: state.notes
            }

        _ ->
            state



-- APP


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( { source = Demo, recording = Ok demoRecording }, Cmd.none )
        , update = update
        , subscriptions = \_ -> Sub.none
        , view = view
        }


type alias Model =
    { source : Source
    , recording : Result String MidiRecording
    }


type Source
    = Demo
    | FromFile String


type Msg
    = MidiFileRequested
    | MidiFileSelected File
    | MidiFileLoaded String Bytes


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MidiFileRequested ->
            ( model, File.Select.file [ "audio/midi", "audio/x-midi", ".mid", ".midi" ] MidiFileSelected )

        MidiFileSelected file ->
            ( model, Task.perform (MidiFileLoaded (File.name file)) (File.toBytes file) )

        MidiFileLoaded name bytes ->
            ( { model | source = FromFile name, recording = fromBytes bytes }, Cmd.none )


view : Model -> Html Msg
view model =
    Html.div
        [ Html.Attributes.style "font-family" "system-ui, sans-serif"
        , Html.Attributes.style "max-width" "1100px"
        , Html.Attributes.style "margin" "0 auto"
        , Html.Attributes.style "padding" "24px 16px 64px 16px"
        , Html.Attributes.style "color" "#1c2733"
        ]
        [ Html.div
            [ Html.Attributes.style "display" "flex"
            , Html.Attributes.style "align-items" "baseline"
            , Html.Attributes.style "gap" "16px"
            , Html.Attributes.style "flex-wrap" "wrap"
            ]
            [ Html.h1
                [ Html.Attributes.style "margin" "0" ]
                [ Html.text "MIDI parser & renderer" ]
            , Html.button
                [ Html.Events.onClick MidiFileRequested
                , Html.Attributes.style "font-size" "15px"
                , Html.Attributes.style "padding" "6px 14px"
                , Html.Attributes.style "cursor" "pointer"
                ]
                [ Html.text "Open MIDI file…" ]
            , Html.span
                [ Html.Attributes.style "color" "#5b6b7b" ]
                [ Html.text
                    (case model.source of
                        Demo ->
                            "showing the built-in demo recording"

                        FromFile name ->
                            name
                    )
                ]
            ]
        , case model.recording of
            Err message ->
                Html.div
                    [ Html.Attributes.style "margin-top" "24px"
                    , Html.Attributes.style "padding" "12px 16px"
                    , Html.Attributes.style "background" "#fdeaea"
                    , Html.Attributes.style "border" "1px solid #e5b4b4"
                    , Html.Attributes.style "border-radius" "6px"
                    ]
                    [ Html.text message ]

            Ok recording ->
                viewRecording recording
        ]


viewRecording : MidiRecording -> Html msg
viewRecording recording =
    let
        extracted =
            extractNotes recording
    in
    Html.div []
        [ viewSummary recording extracted
        , viewChannelLegend extracted.notes
        , viewPianoRoll (ticksPerBeatOf recording) extracted
        , Html.h2 [ Html.Attributes.style "margin" "32px 0 8px 0" ] [ Html.text "Events" ]
        , Html.div [] (List.indexedMap viewTrack (tracksOf recording))
        ]


viewSummary : MidiRecording -> { notes : List PianoNote, totalTicks : Ticks } -> Html msg
viewSummary recording extracted =
    let
        formatText =
            case recording of
                SingleTrack _ _ ->
                    "format 0 (single track)"

                MultipleTracks Simultaneous _ tracks ->
                    "format 1 (" ++ String.fromInt (List.length tracks) ++ " simultaneous tracks)"

                MultipleTracks Independent _ tracks ->
                    "format 2 (" ++ String.fromInt (List.length tracks) ++ " independent tracks)"

        ticksPerBeat =
            ticksPerBeatOf recording

        -- microseconds per beat; MIDI's default is 120 bpm when unspecified
        tempo =
            tracksOf recording
                |> List.concatMap identity
                |> List.filterMap
                    (\( _, event ) ->
                        case event of
                            Tempo microseconds ->
                                Just microseconds

                            _ ->
                                Nothing
                    )
                |> List.head
                |> Maybe.withDefault 500000

        beats =
            toFloat extracted.totalTicks / toFloat (max 1 ticksPerBeat)

        seconds =
            beats * toFloat tempo / 1000000

        items =
            [ formatText
            , String.fromInt ticksPerBeat ++ " ticks/beat"
            , String.fromInt (round (60000000 / toFloat (max 1 tempo))) ++ " bpm"
            , String.fromInt (List.length extracted.notes) ++ " notes"
            , String.fromInt extracted.totalTicks
                ++ " ticks ≈ "
                ++ String.fromFloat (toFloat (round (seconds * 10)) / 10)
                ++ "s"
            ]
    in
    Html.p
        [ Html.Attributes.style "color" "#5b6b7b", Html.Attributes.style "margin" "12px 0" ]
        [ Html.text (String.join "  ·  " items) ]


viewChannelLegend : List PianoNote -> Html msg
viewChannelLegend notes =
    let
        channels =
            List.map .channel notes
                |> List.foldl (\channel set -> Dict.insert channel () set) Dict.empty
                |> Dict.keys
    in
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "gap" "12px"
        , Html.Attributes.style "flex-wrap" "wrap"
        , Html.Attributes.style "margin-bottom" "8px"
        , Html.Attributes.style "font-size" "13px"
        ]
        (List.map
            (\channel ->
                Html.span
                    [ Html.Attributes.style "display" "inline-flex"
                    , Html.Attributes.style "align-items" "center"
                    , Html.Attributes.style "gap" "5px"
                    ]
                    [ Html.span
                        [ Html.Attributes.style "width" "12px"
                        , Html.Attributes.style "height" "12px"
                        , Html.Attributes.style "border-radius" "3px"
                        , Html.Attributes.style "display" "inline-block"
                        , Html.Attributes.style "background" (channelColor channel)
                        ]
                        []
                    , Html.text ("channel " ++ String.fromInt (channel + 1))
                    ]
            )
            channels
        )


viewPianoRoll : Int -> { notes : List PianoNote, totalTicks : Ticks } -> Html msg
viewPianoRoll ticksPerBeat { notes, totalTicks } =
    if List.isEmpty notes then
        Html.p [] [ Html.text "This recording contains no notes, so there is nothing to draw." ]

    else
        let
            safeTotal =
                max 1 totalTicks

            lowNote =
                max 0 ((List.minimum (List.map .note notes) |> Maybe.withDefault 60) - 2)

            highNote =
                min 127 ((List.maximum (List.map .note notes) |> Maybe.withDefault 72) + 2)

            noteHeight =
                7

            beats =
                toFloat safeTotal / toFloat (max 1 ticksPerBeat)

            rollWidth =
                clamp 800 3200 (round (beats * 28))

            pxPerTick =
                toFloat rollWidth / toFloat safeTotal

            rollHeight =
                (highNote - lowNote + 1) * noteHeight

            yFor note =
                (highNote - note) * noteHeight

            isBlackKey note =
                List.member (modBy 12 note) [ 1, 3, 6, 8, 10 ]

            keyRows =
                List.range lowNote highNote
                    |> List.map
                        (\note ->
                            Svg.rect
                                [ Svg.Attributes.x "0"
                                , Svg.Attributes.y (String.fromInt (yFor note))
                                , Svg.Attributes.width (String.fromInt rollWidth)
                                , Svg.Attributes.height (String.fromInt noteHeight)
                                , Svg.Attributes.fill
                                    (if isBlackKey note then
                                        "#e9edf2"

                                     else
                                        "#f7f9fb"
                                    )
                                ]
                                []
                        )

            octaveLabels =
                List.range lowNote highNote
                    |> List.filter (\note -> modBy 12 note == 0)
                    |> List.map
                        (\note ->
                            Svg.text_
                                [ Svg.Attributes.x "3"
                                , Svg.Attributes.y (String.fromInt (yFor note + noteHeight - 1))
                                , Svg.Attributes.fontSize "8"
                                , Svg.Attributes.fill "#8494a5"
                                ]
                                [ Svg.text (noteName note) ]
                        )

            beatLines =
                if beats <= 400 then
                    List.range 0 (ceiling beats)
                        |> List.map
                            (\beat ->
                                let
                                    x =
                                        String.fromFloat (toFloat (beat * ticksPerBeat) * pxPerTick)
                                in
                                Svg.line
                                    [ Svg.Attributes.x1 x
                                    , Svg.Attributes.x2 x
                                    , Svg.Attributes.y1 "0"
                                    , Svg.Attributes.y2 (String.fromInt rollHeight)
                                    , Svg.Attributes.stroke
                                        (if modBy 4 beat == 0 then
                                            "#c3ccd6"

                                         else
                                            "#dde3ea"
                                        )
                                    , Svg.Attributes.strokeWidth "1"
                                    ]
                                    []
                            )

                else
                    []

            noteRects =
                List.map
                    (\pianoNote ->
                        Svg.rect
                            [ Svg.Attributes.x (String.fromFloat (toFloat pianoNote.start * pxPerTick))
                            , Svg.Attributes.y (String.fromFloat (toFloat (yFor pianoNote.note) + 0.5))
                            , Svg.Attributes.width
                                (String.fromFloat (max 2 (toFloat pianoNote.duration * pxPerTick - 0.5)))
                            , Svg.Attributes.height (String.fromInt (noteHeight - 1))
                            , Svg.Attributes.rx "1.5"
                            , Svg.Attributes.fill (channelColor pianoNote.channel)
                            , Svg.Attributes.fillOpacity
                                (String.fromFloat (0.45 + 0.55 * toFloat pianoNote.velocity / 127))
                            ]
                            [ Svg.title []
                                [ Svg.text
                                    (noteName pianoNote.note
                                        ++ "  velocity "
                                        ++ String.fromInt pianoNote.velocity
                                        ++ "  channel "
                                        ++ String.fromInt (pianoNote.channel + 1)
                                        ++ "  track "
                                        ++ String.fromInt (pianoNote.trackIndex + 1)
                                    )
                                ]
                            ]
                    )
                    notes
        in
        Html.div
            [ Html.Attributes.style "overflow-x" "auto"
            , Html.Attributes.style "border" "1px solid #c3ccd6"
            , Html.Attributes.style "border-radius" "6px"
            ]
            [ Svg.svg
                [ Svg.Attributes.width (String.fromInt rollWidth)
                , Svg.Attributes.height (String.fromInt rollHeight)
                , Svg.Attributes.viewBox
                    ("0 0 " ++ String.fromInt rollWidth ++ " " ++ String.fromInt rollHeight)
                , Html.Attributes.style "display" "block"
                ]
                (keyRows ++ beatLines ++ noteRects ++ octaveLabels)
            ]


viewTrack : Int -> Track -> Html msg
viewTrack index track =
    let
        maxShown =
            500

        name =
            track
                |> List.filterMap
                    (\( _, event ) ->
                        case event of
                            TrackName trackName ->
                                Just trackName

                            _ ->
                                Nothing
                    )
                |> List.head

        withAbsoluteTime =
            track
                |> List.foldl
                    (\( deltaTicks, event ) ( time, acc ) ->
                        ( time + deltaTicks, ( time + deltaTicks, deltaTicks, event ) :: acc )
                    )
                    ( 0, [] )
                |> Tuple.second
                |> List.reverse

        cellStyle =
            [ Html.Attributes.style "padding" "1px 14px 1px 0"
            , Html.Attributes.style "text-align" "left"
            , Html.Attributes.style "vertical-align" "top"
            ]

        row ( time, deltaTicks, event ) =
            Html.tr []
                [ Html.td cellStyle [ Html.text (String.fromInt time) ]
                , Html.td cellStyle [ Html.text ("+" ++ String.fromInt deltaTicks) ]
                , Html.td cellStyle [ Html.text (eventToString event) ]
                ]
    in
    Html.details
        [ Html.Attributes.style "margin-bottom" "8px" ]
        [ Html.summary
            [ Html.Attributes.style "cursor" "pointer" ]
            [ Html.text
                ("Track "
                    ++ String.fromInt (index + 1)
                    ++ (case name of
                            Just trackName ->
                                " “" ++ trackName ++ "”"

                            Nothing ->
                                ""
                       )
                    ++ " — "
                    ++ String.fromInt (List.length track)
                    ++ " events"
                )
            ]
        , Html.table
            [ Html.Attributes.style "font-family" "ui-monospace, monospace"
            , Html.Attributes.style "font-size" "12px"
            , Html.Attributes.style "border-collapse" "collapse"
            , Html.Attributes.style "margin" "8px 0 8px 16px"
            ]
            (Html.tr []
                (List.map (\heading -> Html.th cellStyle [ Html.text heading ])
                    [ "time", "delta", "event" ]
                )
                :: List.map row (List.take maxShown withAbsoluteTime)
            )
        , if List.length track > maxShown then
            Html.p
                [ Html.Attributes.style "margin-left" "16px"
                , Html.Attributes.style "color" "#5b6b7b"
                ]
                [ Html.text ("… " ++ String.fromInt (List.length track - maxShown) ++ " more events") ]

          else
            Html.text ""
        ]


eventToString : MidiEvent -> String
eventToString event =
    let
        channelMessage channel name rest =
            "ch " ++ String.fromInt (channel + 1) ++ "  " ++ name ++ " " ++ String.join " " rest
    in
    case event of
        SequenceNumber value ->
            "sequence number " ++ String.fromInt value

        Text text ->
            "text “" ++ text ++ "”"

        Copyright text ->
            "copyright “" ++ text ++ "”"

        TrackName text ->
            "track name “" ++ text ++ "”"

        InstrumentName text ->
            "instrument name “" ++ text ++ "”"

        Lyrics text ->
            "lyrics “" ++ text ++ "”"

        Marker text ->
            "marker “" ++ text ++ "”"

        CuePoint text ->
            "cue point “" ++ text ++ "”"

        ChannelPrefix channel ->
            "channel prefix " ++ String.fromInt channel

        Tempo microseconds ->
            "tempo "
                ++ String.fromInt microseconds
                ++ " µs/beat ("
                ++ String.fromInt (round (60000000 / toFloat (max 1 microseconds)))
                ++ " bpm)"

        SMPTEOffset hour minute second frame frameFraction ->
            "SMPTE offset "
                ++ String.join ":" (List.map String.fromInt [ hour, minute, second, frame, frameFraction ])

        TimeSignature numerator denominator clocks thirtySeconds ->
            "time signature "
                ++ String.fromInt numerator
                ++ "/"
                ++ String.fromInt denominator
                ++ " (clocks/click "
                ++ String.fromInt clocks
                ++ ", 32nds/beat "
                ++ String.fromInt thirtySeconds
                ++ ")"

        KeySignature accidentals mode ->
            "key signature "
                ++ String.fromInt accidentals
                ++ (if mode == 0 then
                        " major"

                    else
                        " minor"
                   )

        SequencerSpecific bytes ->
            "sequencer specific (" ++ String.fromInt (List.length bytes) ++ " bytes)"

        SysEx flavour bytes ->
            "sysex "
                ++ (case flavour of
                        F0 ->
                            "F0"

                        F7 ->
                            "F7"
                   )
                ++ " ("
                ++ String.fromInt (List.length bytes)
                ++ " bytes)"

        Unspecified metaType bytes ->
            "unknown meta 0x"
                ++ toHex metaType
                ++ " ("
                ++ String.fromInt (List.length bytes)
                ++ " bytes)"

        NoteOn channel note velocity ->
            channelMessage channel "note on " [ noteName note, "velocity " ++ String.fromInt velocity ]

        NoteOff channel note velocity ->
            channelMessage channel "note off" [ noteName note, "velocity " ++ String.fromInt velocity ]

        NoteAfterTouch channel note velocity ->
            channelMessage channel "aftertouch" [ noteName note, String.fromInt velocity ]

        ControlChange channel controllerNumber value ->
            channelMessage channel "control change" [ String.fromInt controllerNumber, "= " ++ String.fromInt value ]

        ProgramChange channel value ->
            channelMessage channel "program change" [ String.fromInt value ]

        ChannelAfterTouch channel velocity ->
            channelMessage channel "channel aftertouch" [ String.fromInt velocity ]

        PitchBend channel bend ->
            channelMessage channel "pitch bend" [ String.fromInt bend ]


noteName : Note -> String
noteName note =
    let
        names =
            [ "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" ]

        name =
            List.drop (modBy 12 note) names
                |> List.head
                |> Maybe.withDefault "?"
    in
    name ++ String.fromInt (note // 12 - 1)


toHex : Int -> String
toHex value =
    let
        digit n =
            String.slice n (n + 1) "0123456789ABCDEF"
    in
    digit (Bitwise.and 0x0F (Bitwise.shiftRightBy 4 value)) ++ digit (Bitwise.and 0x0F value)


channelColor : Channel -> String
channelColor channel =
    let
        palette =
            [ "#4269d0"
            , "#efb118"
            , "#ff725c"
            , "#6cc5b0"
            , "#3ca951"
            , "#ff8ab7"
            , "#a463f2"
            , "#97bbf5"
            , "#9c6b4e"
            , "#9498a0"
            , "#e04f60"
            , "#83b552"
            , "#c26fbd"
            , "#f28e2c"
            , "#5c7a8a"
            , "#bcbd22"
            ]
    in
    List.drop (modBy 16 channel) palette
        |> List.head
        |> Maybe.withDefault "#4269d0"



-- DEMO RECORDING


{-| A little four-bar chord progression so the page renders something
interesting before a file is loaded.
-}
demoRecording : MidiRecording
demoRecording =
    let
        ticksPerBeat =
            96

        -- ( bass root, chord triad ) for C, G, Am, F
        chords =
            [ ( 36, [ 60, 64, 67 ] )
            , ( 31, [ 59, 62, 67 ] )
            , ( 33, [ 57, 60, 64 ] )
            , ( 29, [ 57, 60, 65 ] )
            ]

        playNote channel note startBeat lengthBeats velocity =
            [ ( round (startBeat * toFloat ticksPerBeat), NoteOn channel note velocity )
            , ( round ((startBeat + lengthBeats) * toFloat ticksPerBeat), NoteOff channel note 0 )
            ]

        bar barIndex ( bassRoot, chord ) =
            let
                barStart =
                    toFloat (barIndex * 4)

                arpeggio =
                    chord ++ [ (List.head chord |> Maybe.withDefault 60) + 12 ]

                melody =
                    List.indexedMap
                        (\i note ->
                            playNote 0 (note + 12) (barStart + toFloat i * 0.5) 0.5 90
                        )
                        (arpeggio ++ List.reverse arpeggio)
            in
            playNote 1 bassRoot barStart 4 72
                ++ List.concatMap (\note -> playNote 2 note barStart 4 42) chord
                ++ List.concat melody

        eventRank ( _, event ) =
            case event of
                NoteOff _ _ _ ->
                    1

                NoteOn _ _ _ ->
                    2

                _ ->
                    0

        absoluteEvents =
            [ ( 0, TrackName "demo" )
            , ( 0, Tempo 545455 )
            , ( 0, TimeSignature 4 4 24 8 )
            ]
                ++ List.concat (List.indexedMap bar chords)
                |> List.sortBy (\(( time, _ ) as message) -> ( time, eventRank message ))

        toDeltas events =
            events
                |> List.foldl
                    (\( time, event ) ( lastTime, acc ) ->
                        ( time, ( time - lastTime, event ) :: acc )
                    )
                    ( 0, [] )
                |> Tuple.second
                |> List.reverse
    in
    SingleTrack ticksPerBeat (toDeltas absoluteEvents)
