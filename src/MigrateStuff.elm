module MigrateStuff exposing (Msg(..), main)

import Backend
import Browser
import Bytes exposing (Bytes)
import Bytes.Decode exposing (Decoder)
import Bytes.Encode
import Evergreen.Migrate.V215
import Evergreen.V214.Discord
import Evergreen.V214.DmChannel
import Evergreen.V214.Id
import Evergreen.V214.LocalState
import Evergreen.V214.Types
import Evergreen.V215.Types
import File.Download
import Html
import Html.Events
import Http
import Lamdera.Wire3
import Pages.Admin
import SeqDict
import Task
import Time
import Types


type Msg
    = LoadedData (Result String Bytes)
    | PressedDownload


main : Program () (Result String Bytes) Msg
main =
    Browser.element
        { init =
            \_ ->
                ( Err "Loading..."
                , Http.task
                    { method = "GET"
                    , url = "/backend-export-2026-05-13-03:56:33.bin"
                    , headers = []
                    , body = Http.emptyBody
                    , resolver =
                        Http.bytesResolver
                            (\response ->
                                case response of
                                    Http.BadStatus_ _ _ ->
                                        Err ""

                                    Http.GoodStatus_ _ bytes ->
                                        let
                                            _ =
                                                Debug.log "asd2f" ""
                                        in
                                        --case Bytes.Decode.decode Evergreen.V214.Types.w3_decode_BackendModel bytes of
                                        case
                                            Bytes.Decode.decode decodeStreamedBackendModel bytes
                                        of
                                            Just backendModel ->
                                                let
                                                    _ =
                                                        Debug.log "asdf" ""

                                                    bytes2 : Bytes
                                                    bytes2 =
                                                        Evergreen.Migrate.V215.migrate_Types_BackendModel backendModel
                                                            |> Evergreen.V215.Types.w3_encode_BackendModel
                                                            |> Bytes.Encode.encode
                                                in
                                                case Bytes.Decode.decode Types.w3_decode_BackendModel bytes2 of
                                                    Just backendModel3 ->
                                                        let
                                                            backendModel4 =
                                                                Backend.startExport (Time.millisToPosix 0) backendModel3

                                                            exportHelper export =
                                                                case Backend.handleExportBackendStep export of
                                                                    ( Pages.Admin.ExportingFinalStep bytes3, _ ) ->
                                                                        Ok bytes3

                                                                    ( _, Just export2 ) ->
                                                                        exportHelper export2

                                                                    _ ->
                                                                        Err "Failed to export 2"
                                                        in
                                                        case backendModel4.scheduledExportState of
                                                            Just exportState ->
                                                                exportHelper exportState

                                                            Nothing ->
                                                                Err "Failed to export"

                                                    Nothing ->
                                                        Err "Failed to decode 2"

                                            Nothing ->
                                                let
                                                    _ =
                                                        Debug.log "asdf3" ""
                                                in
                                                Err "Failed to decode"

                                    Http.BadUrl_ _ ->
                                        Err ""

                                    Http.Timeout_ ->
                                        Err ""

                                    Http.NetworkError_ ->
                                        Err ""
                            )
                    , timeout = Nothing
                    }
                    |> Task.attempt LoadedData
                )
        , update =
            \msg model ->
                case msg of
                    LoadedData result ->
                        ( result, Cmd.none )

                    PressedDownload ->
                        case model of
                            Ok bytes ->
                                ( model, File.Download.bytes "migrated.bin" "application/octet-stream" bytes )

                            Err _ ->
                                ( model, Cmd.none )
        , view =
            \result ->
                case result of
                    Ok _ ->
                        Html.button [ Html.Events.onClick PressedDownload ] [ Html.text "Download" ]

                    Err error ->
                        Html.text error
        , subscriptions = \_ -> Sub.none
        }


decodeBackendModel : Decoder Evergreen.V214.Types.BackendModel
decodeBackendModel =
    Evergreen.V214.Types.w3_decode_BackendModel


decodeGuild =
    Bytes.Decode.map2 Tuple.pair
        (Evergreen.V214.Id.w3_decode_Id Lamdera.Wire3.failDecode)
        Evergreen.V214.LocalState.w3_decode_BackendGuild


decodeDmChannel : Decoder ( Evergreen.V214.DmChannel.DmChannelId, Evergreen.V214.DmChannel.DmChannel )
decodeDmChannel =
    Bytes.Decode.map2 Tuple.pair
        Evergreen.V214.DmChannel.w3_decode_DmChannelId
        Evergreen.V214.DmChannel.w3_decode_DmChannel


decodeDiscordGuild =
    Bytes.Decode.map2 Tuple.pair
        (Evergreen.V214.Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        Evergreen.V214.LocalState.w3_decode_DiscordBackendGuild


decodeDiscordDmChannel : Decoder ( Evergreen.V214.Discord.Id Evergreen.V214.Discord.PrivateChannelId, Evergreen.V214.DmChannel.DiscordDmChannel )
decodeDiscordDmChannel =
    Bytes.Decode.map2 Tuple.pair
        (Evergreen.V214.Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        Evergreen.V214.DmChannel.w3_decode_DiscordDmChannel


decodeStreamedBackendModel : Decoder Evergreen.V214.Types.BackendModel
decodeStreamedBackendModel =
    Bytes.Decode.map5
        (\baseModel guilds dmChannels discordGuilds discordDmChannels ->
            { baseModel
                | guilds = SeqDict.fromList guilds
                , dmChannels = SeqDict.fromList dmChannels
                , discordGuilds = SeqDict.fromList discordGuilds
                , discordDmChannels = SeqDict.fromList discordDmChannels
            }
        )
        decodeBackendModel
        (decodeLengthPrefixedList decodeGuild)
        (decodeLengthPrefixedList decodeDmChannel)
        (decodeLengthPrefixedList decodeDiscordGuild)
        (decodeLengthPrefixedList decodeDiscordDmChannel)


decodeLengthPrefixedList : Decoder a -> Decoder (List a)
decodeLengthPrefixedList itemDecoder =
    Bytes.Decode.unsignedInt32 Bytes.BE
        |> Bytes.Decode.andThen
            (\count ->
                let
                    _ =
                        Debug.log "count" count
                in
                Bytes.Decode.loop
                    ( count, [] )
                    (\( remaining, acc ) ->
                        if remaining > 0 then
                            Bytes.Decode.map (\item -> Bytes.Decode.Loop ( remaining - 1, item :: acc )) itemDecoder

                        else
                            Bytes.Decode.succeed (Bytes.Decode.Done (List.reverse acc))
                    )
            )
