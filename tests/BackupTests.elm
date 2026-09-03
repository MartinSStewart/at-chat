module BackupTests exposing (tests)

{-| Covers which channels the backup integrity checker picks out of a backup.
The picking happens while the backup is being streamed, so these tests encode a
`BackendModel` in the same format a real backup uses and run the real decoder
over it.
-}

import Backend
import Backup
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Discord
import DmChannel exposing (DiscordDmChannel, DmChannel)
import DmChannelId exposing (DmChannelId)
import Expect
import Id
import IdArray
import LocalState
import Message exposing (Message(..))
import NonemptyDict
import OneToOne
import SeqDict exposing (SeqDict)
import Set
import Test exposing (Test, describe, test)
import Time
import Types exposing (BackendModel)
import UInt64
import Unsafe
import User
import WireHelper


tests : Test
tests =
    describe "Backup"
        [ test "The five longest DM channels are picked, longest first" <|
            \_ ->
                backupWith (dmChannelsWithMessageCounts [ 3, 60, 1, 40, 2, 50, 7 ]) SeqDict.empty
                    |> pickedReferenceNames
                    |> Expect.equal
                        (Ok
                            [ dmReference 1 60
                            , dmReference 1 50
                            , dmReference 1 40
                            , dmReference 1 7
                            , dmReference 1 3
                            ]
                        )
        , test "Fewer DM channels than the limit are all picked" <|
            \_ ->
                backupWith (dmChannelsWithMessageCounts [ 2, 9 ]) SeqDict.empty
                    |> pickedReferenceNames
                    |> Expect.equal (Ok [ dmReference 1 9, dmReference 1 2 ])
        , test "A DM channel that ties with a picked one doesn't displace it" <|
            \_ ->
                -- The first four are picked outright. The fifth and sixth both
                -- have 5 messages, so the fifth keeps the last slot.
                backupWith (dmChannelsWithMessageCounts [ 9, 8, 7, 6, 5, 5 ]) SeqDict.empty
                    |> pickedReferenceNames
                    |> Expect.equal
                        (Ok
                            [ dmReference 1 9
                            , dmReference 1 8
                            , dmReference 1 7
                            , dmReference 1 6
                            , dmReference 1 5
                            ]
                        )
        , test "Discord DM channels are picked the same way, after the normal ones" <|
            \_ ->
                backupWith
                    (dmChannelsWithMessageCounts [ 4 ])
                    (discordDmChannelsWithMessageCounts [ 1, 30, 20 ])
                    |> pickedReferenceNames
                    |> Expect.equal
                        (Ok
                            [ dmReference 1 4
                            , "discord-dm-30.json"
                            , "discord-dm-20.json"
                            , "discord-dm-1.json"
                            ]
                        )
        , test "Every DM channel is noted, including the ones that weren't picked" <|
            \_ ->
                backupWith
                    (dmChannelsWithMessageCounts [ 3, 60, 1, 40, 2, 50, 7 ])
                    (discordDmChannelsWithMessageCounts [ 8 ])
                    |> Result.map (\backup -> Set.member (dmReference 1 1) backup.channelsInBackup)
                    |> Expect.equal (Ok True)
        , test "A backup with no DM channels still decodes" <|
            \_ ->
                backupWith SeqDict.empty SeqDict.empty
                    |> pickedReferenceNames
                    |> Expect.equal (Ok [])
        , test "Splitting off a chunk gives back that many bytes plus the rest" <|
            \_ ->
                Backend.splitOffChunk 4 (bytesFromValues (List.range 1 10))
                    |> (\( chunk, rest ) -> ( toByteValues chunk, toByteValues rest ))
                    |> Expect.equal ( List.range 1 4, List.range 5 10 )
        , test "Splitting off more bytes than there are gives back everything and an empty remainder" <|
            \_ ->
                Backend.splitOffChunk 20 (bytesFromValues (List.range 1 10))
                    |> (\( chunk, rest ) -> ( toByteValues chunk, toByteValues rest ))
                    |> Expect.equal ( List.range 1 10, [] )
        , test "A backup is split into chunks that are no larger than the chunk size" <|
            \_ ->
                bytesFromValues (List.range 1 10)
                    |> backupChunks 3
                    |> List.map Bytes.width
                    |> Expect.equal [ 3, 3, 3, 1 ]
        , test "Chunks reassemble into the original backup" <|
            \_ ->
                bytesFromValues (List.range 1 10)
                    |> backupChunks 3
                    |> List.map Bytes.Encode.bytes
                    |> Bytes.Encode.sequence
                    |> Bytes.Encode.encode
                    |> toByteValues
                    |> Expect.equal (List.range 1 10)
        ]


{-| The chunks the admin page ends up with, in the order it reassembles them. The backend
keeps splitting a chunk off the backup until nothing is left over, and the admin page
prepends each chunk as it arrives and reverses them once it has them all.
-}
backupChunks : Int -> Bytes -> List Bytes
backupChunks chunkWidth backup =
    let
        collect : Bytes -> List Bytes -> List Bytes
        collect remaining chunksNewestFirst =
            let
                ( chunk, rest ) =
                    Backend.splitOffChunk chunkWidth remaining
            in
            if Bytes.width rest > 0 then
                collect rest (chunk :: chunksNewestFirst)

            else
                chunk :: chunksNewestFirst
    in
    collect backup [] |> List.reverse


bytesFromValues : List Int -> Bytes
bytesFromValues values =
    List.map Bytes.Encode.unsignedInt8 values
        |> Bytes.Encode.sequence
        |> Bytes.Encode.encode


toByteValues : Bytes -> List Int
toByteValues bytes =
    Bytes.Decode.decode
        (Bytes.Decode.loop ( Bytes.width bytes, [] )
            (\( remaining, acc ) ->
                if remaining <= 0 then
                    Bytes.Decode.succeed (Bytes.Decode.Done (List.reverse acc))

                else
                    Bytes.Decode.map
                        (\value -> Bytes.Decode.Loop ( remaining - 1, value :: acc ))
                        Bytes.Decode.unsignedInt8
            )
        )
        bytes
        |> Maybe.withDefault []


{-| Only the DM channels matter here, so the guilds `Backend.init` comes with
are left alone. Their exports show up ahead of the DM ones, which is why the
expectations above only look at names starting with `dm-` and `discord-dm-`.
-}
backupWith :
    SeqDict DmChannelId DmChannel
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordDmChannel
    -> Result String Backup.Backup
backupWith dmChannels discordDmChannels =
    let
        ( baseModel, _ ) =
            Backend.app_.init

        model : BackendModel
        model =
            { baseModel
                | users =
                    NonemptyDict.toSeqDict baseModel.users
                        |> SeqDict.insert (Id.fromInt 1) testUser
                        |> SeqDict.toList
                        |> NonemptyDict.fromList
                        |> Maybe.withDefault baseModel.users
                , dmChannels = dmChannels
                , discordDmChannels = discordDmChannels
            }
    in
    case Bytes.Decode.decode Backup.decodeBackup (encodeStreamed model) of
        Just backup ->
            Ok backup

        Nothing ->
            Err "The encoded backup could not be decoded"


{-| The same layout `handleExportBackendStep` writes: the model, then a
length-prefixed list for each of the four sections it strips out of it.
-}
encodeStreamed : BackendModel -> Bytes
encodeStreamed model =
    Bytes.Encode.sequence
        [ Bytes.Encode.bytes (Bytes.Encode.encode (WireHelper.encodeBackendModel model))
        , lengthPrefixed encodeGuild (SeqDict.toList model.guilds)
        , lengthPrefixed WireHelper.encodeDmChannel (SeqDict.toList model.dmChannels)
        , lengthPrefixed encodeDiscordGuild (SeqDict.toList model.discordGuilds)
        , lengthPrefixed WireHelper.encodeDiscordDmChannel (SeqDict.toList model.discordDmChannels)
        ]
        |> Bytes.Encode.encode


{-| A guild is written as a header and then one encoding per channel, the same
way the export steps build it up.
-}
encodeGuild : ( Id.Id Id.GuildId, LocalState.BackendGuild ) -> Bytes.Encode.Encoder
encodeGuild ( guildId, guild ) =
    Bytes.Encode.sequence
        (WireHelper.encodeGuildHeader ( guildId, guild )
            :: List.map WireHelper.encodeGuildChannel (SeqDict.toList guild.channels)
        )


encodeDiscordGuild : ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild ) -> Bytes.Encode.Encoder
encodeDiscordGuild ( guildId, guild ) =
    Bytes.Encode.sequence
        (WireHelper.encodeDiscordGuildHeader ( guildId, guild )
            :: List.map WireHelper.encodeDiscordGuildChannel (SeqDict.toList guild.channels)
        )


lengthPrefixed : (a -> Bytes.Encode.Encoder) -> List a -> Bytes.Encode.Encoder
lengthPrefixed encoder items =
    Bytes.Encode.sequence
        (Bytes.Encode.unsignedInt32 Bytes.BE (List.length items) :: List.map encoder items)


{-| Each channel is a DM between user 1 and a user numbered after its message
count, so a channel's reference name says how long it is.
-}
dmChannelsWithMessageCounts : List Int -> SeqDict DmChannelId DmChannel
dmChannelsWithMessageCounts messageCounts =
    List.map
        (\messageCount ->
            ( DmChannelId.fromUserIds (Id.fromInt 1) (Id.fromInt messageCount)
            , { backendInit | messages = messages messageCount }
            )
        )
        messageCounts
        |> SeqDict.fromList


unsafeUserId : Discord.Id Discord.UserId
unsafeUserId =
    Discord.idFromUInt64 (Unsafe.uint64 "1")


discordDmChannelsWithMessageCounts :
    List Int
    -> SeqDict (Discord.Id Discord.PrivateChannelId) DiscordDmChannel
discordDmChannelsWithMessageCounts messageCounts =
    List.map
        (\messageCount ->
            ( Discord.idFromUInt64 (UInt64.fromInt messageCount)
            , { messages = messages messageCount
              , lastTypedAt = SeqDict.empty
              , linkedMessageIds = OneToOne.empty
              , members = NonemptyDict.singleton unsafeUserId { messagesSent = messageCount }
              , dateDividerDrawings = SeqDict.empty
              }
            )
        )
        messageCounts
        |> SeqDict.fromList


backendInit : DmChannel
backendInit =
    DmChannel.backendInit


{-| Deleted messages are the cheapest kind to build and all that matters here is
how many there are.
-}
messages : Int -> IdArray.IdArray messageId (Message messageId userId)
messages count =
    List.range 1 count
        |> List.map (\index -> DeletedMessage (Time.millisToPosix index))
        |> IdArray.fromList


dmReference : Int -> Int -> String
dmReference userIdA userIdB =
    "dm-"
        ++ DmChannelId.toString (DmChannelId.fromUserIds (Id.fromInt userIdA) (Id.fromInt userIdB))
        ++ ".json"


pickedReferenceNames : Result String Backup.Backup -> Result String (List String)
pickedReferenceNames =
    Result.map
        (\backup ->
            List.map .referenceName backup.channels
                |> List.filter (\name -> String.startsWith "dm-" name || String.startsWith "discord-dm-" name)
        )


testUser : User.BackendUser
testUser =
    User.init (Time.millisToPosix 0) (Unsafe.personName "Sven") (Unsafe.emailAddress "sven@example.com") False
