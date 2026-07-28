module WireHelper exposing
    ( decodeStreamedBackendModel
    , encodeBackendModel
    , encodeDiscordDmChannel
    , encodeDiscordGuild
    , encodeDmChannel
    , encodeGuild
    , foldStreamedBackendModel
    )

{-| These functions are in a separate module because Intellij flags w3\_\* functions as missing and that's annoying to look at while doing other stuff.
-}

import Bytes
import Bytes.Decode exposing (Decoder)
import Bytes.Encode exposing (Encoder)
import Discord
import DmChannel
import DmChannelId exposing (DmChannelId)
import Id exposing (GuildId, Id)
import Lamdera.Wire3
import LocalState
import SeqDict
import Types exposing (BackendModel)


encodeBackendModel : BackendModel -> Encoder
encodeBackendModel =
    Types.w3_encode_BackendModel


decodeBackendModel : Decoder BackendModel
decodeBackendModel =
    Types.w3_decode_BackendModel


encodeGuild : ( Id GuildId, LocalState.BackendGuild ) -> Encoder
encodeGuild ( key, value ) =
    Bytes.Encode.sequence
        [ Id.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_BackendGuild value
        ]


decodeGuild : Decoder ( Id GuildId, LocalState.BackendGuild )
decodeGuild =
    Bytes.Decode.map2 Tuple.pair
        (Id.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_BackendGuild


encodeDmChannel : ( DmChannelId, DmChannel.DmChannel ) -> Encoder
encodeDmChannel ( key, value ) =
    Bytes.Encode.sequence
        [ DmChannelId.w3_encode_DmChannelId key
        , DmChannel.w3_encode_DmChannel value
        ]


decodeDmChannel : Decoder ( DmChannelId, DmChannel.DmChannel )
decodeDmChannel =
    Bytes.Decode.map2 Tuple.pair
        DmChannelId.w3_decode_DmChannelId
        DmChannel.w3_decode_DmChannel


encodeDiscordGuild : ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild ) -> Encoder
encodeDiscordGuild ( key, value ) =
    Bytes.Encode.sequence
        [ Discord.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_DiscordBackendGuild value
        ]


decodeDiscordGuild : Decoder ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild )
decodeDiscordGuild =
    Bytes.Decode.map2 Tuple.pair
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_DiscordBackendGuild


encodeDiscordDmChannel : ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel ) -> Encoder
encodeDiscordDmChannel ( key, value ) =
    Bytes.Encode.sequence
        [ Discord.w3_encode_Id Lamdera.Wire3.failEncode key
        , DmChannel.w3_encode_DiscordDmChannel value
        ]


decodeDiscordDmChannel : Decoder ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel )
decodeDiscordDmChannel =
    Bytes.Decode.map2 Tuple.pair
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        DmChannel.w3_decode_DiscordDmChannel


decodeStreamedBackendModel : Decoder BackendModel
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


{-| Reads the same format as `decodeStreamedBackendModel`, but hands each guild
and DM channel to a fold function as it is decoded instead of collecting them
all.

A backup expands to more than twenty times its file size once it has been decoded
into a `BackendModel`, so anything that only needs a part of one should fold it
away here rather than decode the whole thing and pick through it afterwards. Only
one guild is alive at a time, and `init` is the chance to keep whatever is needed
from the rest of the model before that is dropped too. A fold function that hangs
on to what it is handed gives up that guarantee, so it should keep a bounded
amount.

-}
foldStreamedBackendModel :
    { init : BackendModel -> state
    , guild : ( Id GuildId, LocalState.BackendGuild ) -> state -> state
    , dmChannel : ( DmChannelId, DmChannel.DmChannel ) -> state -> state
    , discordGuild : ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild ) -> state -> state
    , discordDmChannel : ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel ) -> state -> state
    }
    -> Decoder state
foldStreamedBackendModel config =
    Bytes.Decode.map config.init decodeBackendModel
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeGuild config.guild)
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeDmChannel config.dmChannel)
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeDiscordGuild config.discordGuild)
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeDiscordDmChannel config.discordDmChannel)


decodeLengthPrefixedList : Decoder a -> Decoder (List a)
decodeLengthPrefixedList itemDecoder =
    foldLengthPrefixedList itemDecoder (::) [] |> Bytes.Decode.map List.reverse


foldLengthPrefixedList : Decoder a -> (a -> state -> state) -> state -> Decoder state
foldLengthPrefixedList itemDecoder func state =
    Bytes.Decode.unsignedInt32 Bytes.BE
        |> Bytes.Decode.andThen
            (\count ->
                Bytes.Decode.loop
                    ( count, state )
                    (\( remaining, state2 ) ->
                        if remaining > 0 then
                            Bytes.Decode.map
                                (\item -> Bytes.Decode.Loop ( remaining - 1, func item state2 ))
                                itemDecoder

                        else
                            Bytes.Decode.succeed (Bytes.Decode.Done state2)
                    )
            )
