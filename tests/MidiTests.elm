module MidiTests exposing (suite)

{-| Tests for the Midi module.

The fuzz tests are ported from newlandsvalley/elm-comidi (Elm 0.18) — the
library src/Midi.elm is modelled on — updated to elm-explorations/test 2.x
and to elm/bytes instead of "binary" Strings. The unit tests at the bottom
cover byte-level details (running status, note-on with velocity zero, header
overspill) that the round-trip fuzzers can't reach because the encoder never
produces them.

-}

import Bytes exposing (Bytes)
import Bytes.Encode as Encode
import Expect
import Fuzz exposing (Fuzzer, intRange)
import Midi exposing (MidiEvent(..), MidiRecording(..), SysExFlavour(..), TracksType(..))
import Test exposing (Test, describe, fuzz, test)



-- FUZZERS


fuzzChannel : Fuzzer Int
fuzzChannel =
    intRange 0 15


fuzzNote : Fuzzer Int
fuzzNote =
    intRange 0 127


fuzzVelocity : Fuzzer Int
fuzzVelocity =
    intRange 0 127


fuzzPositiveVelocity : Fuzzer Int
fuzzPositiveVelocity =
    intRange 1 127


fuzzControllerNumber : Fuzzer Int
fuzzControllerNumber =
    intRange 0 119


fuzzNoteOn : Fuzzer MidiEvent
fuzzNoteOn =
    -- velocity zero would turn into a NoteOff
    Fuzz.map3 NoteOn fuzzChannel fuzzNote fuzzPositiveVelocity


fuzzNoteOff : Fuzzer MidiEvent
fuzzNoteOff =
    Fuzz.map3 NoteOff fuzzChannel fuzzNote fuzzVelocity


fuzzNoteAfterTouch : Fuzzer MidiEvent
fuzzNoteAfterTouch =
    Fuzz.map3 NoteAfterTouch fuzzChannel fuzzNote fuzzVelocity


fuzzControlChange : Fuzzer MidiEvent
fuzzControlChange =
    Fuzz.map3 ControlChange fuzzChannel fuzzControllerNumber fuzzVelocity


fuzzProgramChange : Fuzzer MidiEvent
fuzzProgramChange =
    Fuzz.map2 ProgramChange fuzzChannel (intRange 0 127)


fuzzChannelAfterTouch : Fuzzer MidiEvent
fuzzChannelAfterTouch =
    Fuzz.map2 ChannelAfterTouch fuzzChannel (intRange 0 127)


fuzzPitchBend : Fuzzer MidiEvent
fuzzPitchBend =
    Fuzz.map2 PitchBend fuzzChannel (intRange 0 16383)


fuzzSysExByte : Fuzzer Int
fuzzSysExByte =
    intRange 0 127


fuzzByte : Fuzzer Int
fuzzByte =
    intRange 0 255


fuzzAsciiString : Fuzzer String
fuzzAsciiString =
    Fuzz.listOfLengthBetween 0 20 (intRange 32 126)
        |> Fuzz.map (List.map Char.fromCode >> String.fromList)


fuzzMetaEvent : Fuzzer MidiEvent
fuzzMetaEvent =
    Fuzz.oneOf
        [ Fuzz.map SequenceNumber (intRange 0 0xFFFF)
        , Fuzz.map Text fuzzAsciiString
        , Fuzz.map Copyright fuzzAsciiString
        , Fuzz.map TrackName fuzzAsciiString
        , Fuzz.map InstrumentName fuzzAsciiString
        , Fuzz.map Lyrics fuzzAsciiString
        , Fuzz.map Marker fuzzAsciiString
        , Fuzz.map CuePoint fuzzAsciiString
        , Fuzz.map ChannelPrefix (intRange 0 15)
        , Fuzz.map Tempo (intRange 1 0x00FFFFFF)
        , Fuzz.map5 SMPTEOffset (intRange 0 23) (intRange 0 59) (intRange 0 59) (intRange 0 30) (intRange 0 99)
        , Fuzz.map4 TimeSignature
            (intRange 1 32)
            (Fuzz.map (\exponent -> 2 ^ exponent) (intRange 0 7))
            (intRange 1 96)
            (intRange 1 32)
        , Fuzz.map2 KeySignature (intRange -7 7) (intRange 0 1)
        , Fuzz.map SequencerSpecific (Fuzz.listOfLengthBetween 0 20 fuzzByte)
        ]


commonEvents : List (Fuzzer MidiEvent)
commonEvents =
    [ fuzzNoteOn
    , fuzzNoteOff
    , fuzzNoteAfterTouch
    , fuzzControlChange
    , fuzzProgramChange
    , fuzzChannelAfterTouch
    , fuzzPitchBend
    ]


{-| A standalone (Web MIDI style) SysEx event: no length prefix, terminated
by EOX, so the data bytes must all be < 128.
-}
fuzzSysExEvent : Fuzzer MidiEvent
fuzzSysExEvent =
    Fuzz.map (SysEx F0) (Fuzz.listOfLengthBetween 0 32 fuzzSysExByte)


fuzzMidiEvent : Fuzzer MidiEvent
fuzzMidiEvent =
    Fuzz.oneOf (commonEvents ++ [ fuzzSysExEvent, fuzzMetaEvent ])


{-| SysEx events as stored in a MIDI file: length-prefixed, so the escaped
(F7) flavour may contain arbitrary bytes.
-}
fuzzSysExFileEvent : Fuzzer MidiEvent
fuzzSysExFileEvent =
    Fuzz.oneOf
        [ Fuzz.map (SysEx F0) (Fuzz.listOfLengthBetween 0 48 fuzzSysExByte)
        , Fuzz.map (SysEx F7) (Fuzz.listOfLengthBetween 0 48 fuzzByte)
        ]


fuzzMidiFileEvent : Fuzzer MidiEvent
fuzzMidiFileEvent =
    Fuzz.oneOf (commonEvents ++ [ fuzzSysExFileEvent, fuzzMetaEvent ])


fuzzTicks : Fuzzer Int
fuzzTicks =
    intRange 0 0x0FFFFFFF


fuzzMidiMessage : Fuzzer ( Int, MidiEvent )
fuzzMidiMessage =
    Fuzz.pair fuzzTicks fuzzMidiFileEvent


fuzzTrack : Fuzzer (List ( Int, MidiEvent ))
fuzzTrack =
    Fuzz.frequency
        [ ( 25, Fuzz.constant [] )
        , ( 60, Fuzz.listOfLengthBetween 1 8 fuzzMidiMessage )
        , ( 14, Fuzz.listOfLengthBetween 32 64 fuzzMidiMessage )
        , ( 1, Fuzz.listOfLengthBetween 128 256 fuzzMidiMessage )
        ]


fuzzMidiRecording : Fuzzer MidiRecording
fuzzMidiRecording =
    let
        fuzzTicksPerBeat =
            intRange 1 0x7FFF

        multipleTracks tracksType =
            Fuzz.map2 (MultipleTracks tracksType)
                fuzzTicksPerBeat
                (Fuzz.listOfLengthBetween 0 8 fuzzTrack)
    in
    Fuzz.oneOf
        [ Fuzz.map2 SingleTrack fuzzTicksPerBeat fuzzTrack
        , multipleTracks Simultaneous
        , multipleTracks Independent
        ]



-- HELPERS


bytesFromList : List Int -> Bytes
bytesFromList list =
    Encode.encode (Encode.sequence (List.map Encode.unsignedInt8 list))


{-| Convert a standalone event to how it would appear in a MIDI file: an
unescaped SysEx message needs its EOX terminator stored explicitly.
-}
toFileEvent : MidiEvent -> MidiEvent
toFileEvent event =
    case event of
        SysEx F0 bytes ->
            SysEx F0 (bytes ++ [ Midi.eox ])

        _ ->
            event



-- TESTS


suite : Test
suite =
    describe "MIDI tests"
        [ roundTripTests
        , parserUnitTests
        ]


roundTripTests : Test
roundTripTests =
    describe "round trips"
        [ fuzz fuzzMidiEvent "go from MidiEvent to bytes and back" <|
            \event ->
                Midi.eventFromBytes (Midi.eventToBytes event)
                    |> Expect.equal (Ok event)
        , fuzz fuzzMidiRecording "go from MidiRecording to bytes and back" <|
            \recording ->
                Midi.fromBytes (Midi.toBytes recording)
                    |> Expect.equal (Ok recording)
        , fuzz (Fuzz.pair fuzzChannel fuzzNote)
            "NoteOn with velocity zero looks like NoteOff with velocity zero"
          <|
            \( channel, note ) ->
                Midi.eventFromBytes (Midi.eventToBytes (NoteOn channel note 0))
                    |> Expect.equal (Midi.eventFromBytes (Midi.eventToBytes (NoteOff channel note 0)))
        , fuzz (Fuzz.list (Fuzz.pair fuzzTicks fuzzMidiEvent))
            "ensure toFileEvent helper works correctly"
          <|
            \midiEventSequence ->
                let
                    midiMessages =
                        List.map (\( ticks, event ) -> ( ticks, toFileEvent event )) midiEventSequence
                in
                Midi.validRecording (SingleTrack 1 midiMessages)
                    |> Expect.equal True
        ]


{-| MThd chunk for a format 0 file with one track and 96 ticks/beat
-}
format0Header : List Int
format0Header =
    [ 0x4D, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x01, 0x00, 0x60 ]


{-| MTrk chunk holding the given event bytes (which must include the
end-of-track event)
-}
trackChunk : List Int -> List Int
trackChunk eventBytes =
    [ 0x4D, 0x54, 0x72, 0x6B, 0x00, 0x00, 0x00, List.length eventBytes ] ++ eventBytes


endOfTrack : List Int
endOfTrack =
    [ 0x00, 0xFF, 0x2F, 0x00 ]


parserUnitTests : Test
parserUnitTests =
    describe "parser unit tests"
        [ test "running status reuses the previous status byte" <|
            \_ ->
                bytesFromList
                    (format0Header
                        ++ trackChunk
                            ([ 0x00, 0x90, 0x3C, 0x40 ]
                                ++ [ 0x10, 0x3E, 0x50 ]
                                ++ [ 0x00, 0x80, 0x3C, 0x00 ]
                                ++ endOfTrack
                            )
                    )
                    |> Midi.fromBytes
                    |> Expect.equal
                        (Ok
                            (SingleTrack 96
                                [ ( 0, NoteOn 0 60 64 )
                                , ( 16, NoteOn 0 62 80 )
                                , ( 0, NoteOff 0 60 0 )
                                ]
                            )
                        )
        , test "running status survives a velocity-zero note-on" <|
            \_ ->
                -- the second data pair (velocity 0) parses as NoteOff but the
                -- running status stays 0x90, so the third pair is a NoteOn
                bytesFromList
                    (format0Header
                        ++ trackChunk
                            ([ 0x00, 0x90, 0x3C, 0x40 ]
                                ++ [ 0x60, 0x3C, 0x00 ]
                                ++ [ 0x00, 0x3E, 0x40 ]
                                ++ endOfTrack
                            )
                    )
                    |> Midi.fromBytes
                    |> Expect.equal
                        (Ok
                            (SingleTrack 96
                                [ ( 0, NoteOn 0 60 64 )
                                , ( 96, NoteOff 0 60 0 )
                                , ( 0, NoteOn 0 62 64 )
                                ]
                            )
                        )
        , test "note-on with velocity zero parses as note-off" <|
            \_ ->
                bytesFromList
                    (format0Header
                        ++ trackChunk ([ 0x00, 0x93, 0x3C, 0x00 ] ++ endOfTrack)
                    )
                    |> Midi.fromBytes
                    |> Expect.equal (Ok (SingleTrack 96 [ ( 0, NoteOff 3 60 0 ) ]))
        , test "extra header bytes in a non-standard size chunk are skipped" <|
            \_ ->
                bytesFromList
                    ([ 0x4D, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x08 ]
                        ++ [ 0x00, 0x00, 0x00, 0x01, 0x00, 0x60 ]
                        ++ [ 0xAB, 0xCD ]
                        ++ trackChunk endOfTrack
                    )
                    |> Midi.fromBytes
                    |> Expect.equal (Ok (SingleTrack 96 []))
        , test "format 1 file with two tracks" <|
            \_ ->
                bytesFromList
                    ([ 0x4D, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x01, 0x00, 0x02, 0x01, 0x80 ]
                        ++ trackChunk ([ 0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20 ] ++ endOfTrack)
                        ++ trackChunk ([ 0x00, 0xC5, 0x08, 0x00, 0xE5, 0x00, 0x40 ] ++ endOfTrack)
                    )
                    |> Midi.fromBytes
                    |> Expect.equal
                        (Ok
                            (MultipleTracks Simultaneous
                                384
                                [ [ ( 0, Tempo 500000 ) ]
                                , [ ( 0, ProgramChange 5 8 ), ( 0, PitchBend 5 8192 ) ]
                                ]
                            )
                        )
        , test "text meta event" <|
            \_ ->
                bytesFromList
                    (format0Header
                        ++ trackChunk
                            ([ 0x00, 0xFF, 0x01, 0x05, 0x68, 0x65, 0x6C, 0x6C, 0x6F ] ++ endOfTrack)
                    )
                    |> Midi.fromBytes
                    |> Expect.equal (Ok (SingleTrack 96 [ ( 0, Text "hello" ) ]))
        , test "unknown meta events are kept as Unspecified" <|
            \_ ->
                bytesFromList
                    (format0Header
                        ++ trackChunk ([ 0x00, 0xFF, 0x60, 0x02, 0x12, 0x34 ] ++ endOfTrack)
                    )
                    |> Midi.fromBytes
                    |> Expect.equal (Ok (SingleTrack 96 [ ( 0, Unspecified 0x60 [ 0x12, 0x34 ] ) ]))
        , test "not a MIDI file" <|
            \_ ->
                bytesFromList [ 0x12, 0x34, 0x56, 0x78 ]
                    |> Midi.fromBytes
                    |> Expect.err
        ]
