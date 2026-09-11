module ChannelImportTests exposing (tests)

{-| Covers that a channel written by `ChannelExport` comes back as the same channel when
`ChannelImport` reads it, since the two have to agree on a format that nothing type checks.
-}

import Array
import Bytes.Encode
import ChannelDescription
import ChannelExport
import ChannelImport
import Date
import Drawing exposing (Drawing)
import Emoji exposing (EmojiOrCustomEmoji(..))
import Encryption
import Expect
import Id exposing (Id, UserId)
import IdArray
import Json.Decode
import List.Nonempty
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..))
import MembersAndOwner
import Message exposing (Message(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import RichText
import SeqDict
import SeqSet
import String.Nonempty
import Test exposing (Test)
import Thread exposing (BackendThread)
import Time
import Unsafe
import User exposing (BackendUser)


tests : Test
tests =
    Test.describe "ChannelImport"
        [ Test.test "An exported channel is imported with the same name and description" <|
            \_ ->
                importedChannel
                    |> Result.map (\channel -> ( channel.name, channel.description ))
                    |> Expect.equal (Ok ( testChannel.name, testChannel.description ))
        , Test.test "Messages come back the way they were written" <|
            \_ ->
                importedChannel
                    |> Result.map (\channel -> IdArray.toList channel.messages)
                    |> Expect.equal (Ok (IdArray.toList testChannel.messages))
        , Test.test "A message's thread comes back with it" <|
            \_ ->
                importedChannel
                    |> Result.map .threads
                    |> Expect.equal (Ok testChannel.threads)
        , Test.test "Drawings on the dividers between days come back" <|
            \_ ->
                importedChannel
                    |> Result.map .dateDividerDrawings
                    |> Expect.equal (Ok testChannel.dateDividerDrawings)
        , Test.test "An encrypted message is imported as a deleted message and counted" <|
            \_ ->
                (case ChannelImport.decode (exportOf { testChannel | messages = IdArray.fromList [ encryptedMessage ] }) of
                    Ok channel ->
                        Ok ( IdArray.toList channel.messages, channel.encryptedMessages )

                    Err error ->
                        Err error
                )
                    |> Expect.equal (Ok ( [ DeletedMessage (time 4) ], 1 ))
        , Test.test "An encrypted message in a thread is counted too" <|
            \_ ->
                (case
                    ChannelImport.decode
                        (exportOf
                            { testChannel
                                | messages = IdArray.fromList [ textMessage ]
                                , threads =
                                    SeqDict.singleton
                                        (Id.fromInt 0)
                                        { messages = IdArray.fromList [ encryptedMessage ]
                                        , lastTypedAt = SeqDict.empty
                                        , dateDividerDrawings = SeqDict.empty
                                        }
                            }
                        )
                 of
                    Ok channel ->
                        Ok channel.encryptedMessages

                    Err error ->
                        Err error
                )
                    |> Expect.equal (Ok 1)
        , Test.test "A file that isn't a channel export is turned down" <|
            \_ ->
                ChannelImport.decode "not a channel export"
                    |> Result.toMaybe
                    |> Expect.equal Nothing
        ]


importedChannel : Result Json.Decode.Error ChannelImport.ImportedChannel
importedChannel =
    ChannelImport.decode (exportOf testChannel)


exportOf : BackendChannel -> String
exportOf channel =
    ChannelExport.guildChannel users testGuild channel


adminId : Id UserId
adminId =
    Id.fromInt 0


otherUserId : Id UserId
otherUserId =
    Id.fromInt 1


users : NonemptyDict (Id UserId) BackendUser
users =
    NonemptyDict.fromNonemptyList
        (List.Nonempty.Nonempty ( adminId, admin ) [ ( otherUserId, otherUser ) ])


admin : BackendUser
admin =
    User.init (time 0) (Unsafe.personName "Martin") (Unsafe.emailAddress "martin@example.com") False


otherUser : BackendUser
otherUser =
    User.init (time 0) (Unsafe.personName "Sven") (Unsafe.emailAddress "sven@example.com") False


time : Int -> Time.Posix
time seconds =
    Time.millisToPosix (seconds * 1000)


testGuild : BackendGuild
testGuild =
    { createdAt = time 0
    , createdBy = adminId
    , name = Unsafe.guildName "Test guild"
    , icon = Nothing
    , channels = SeqDict.empty
    , membersAndOwner =
        MembersAndOwner.init (SeqDict.singleton otherUserId { joinedAt = time 1 }) adminId
    , invites = SeqDict.empty
    }


{-| A channel with the parts of a message that used to be dropped by the export: a drawing on a
message, a drawing on a date divider, and a thread that has both.
-}
testChannel : BackendChannel
testChannel =
    { createdAt = time 0
    , createdBy = adminId
    , name = Unsafe.channelName "general"
    , description = ChannelDescription.fromStringLossy "What everyone talks in"
    , messages = IdArray.fromList [ textMessage, Message.userJoined (time 3) otherUserId ]
    , status = ChannelActive
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.singleton (Id.fromInt 0) testThread
    , dateDividerDrawings = SeqDict.singleton (Date.fromRataDie 738000) (drawing adminId)
    , games = SeqDict.empty
    }


testThread : BackendThread
testThread =
    { messages = IdArray.fromList [ textMessage ]
    , lastTypedAt = SeqDict.empty
    , dateDividerDrawings = SeqDict.singleton (Date.fromRataDie 738001) (drawing otherUserId)
    }


textMessage : Message messageId (Id UserId)
textMessage =
    UserTextMessage
        { createdAt = time 2
        , createdBy = adminId
        , content =
            { content =
                RichText.fromNonemptyString
                    Time.utc
                    (NonemptyDict.toSeqDict users)
                    (String.Nonempty.NonemptyString 'H' "ello @Sven, welcome!")
            , attachedFiles = SeqDict.empty
            , embeds = Array.empty
            }
        , reactions =
            SeqDict.singleton
                (EmojiOrCustomEmoji_Emoji (Emoji.fromString "😀"))
                (NonemptySet.singleton otherUserId)
        , editedAt = Just (time 3)
        , repliedTo = Nothing
        , drawings =
            Just
                { timestampDrawings = Drawing.emptyDrawing
                , userIconDrawings = drawing adminId
                , imageAttachmentDrawings = SeqDict.empty
                , embedDrawings = SeqDict.empty
                }
        }


encryptedMessage : Message messageId (Id UserId)
encryptedMessage =
    EncryptedUserTextMessage
        { createdAt = time 4
        , createdBy = adminId
        , content = Encryption.encryptedData (Bytes.Encode.encode (Bytes.Encode.unsignedInt8 1))
        , fileHashes = SeqSet.empty
        , reactions = SeqDict.empty
        , editedAt = Nothing
        , repliedTo = Nothing
        , drawings = Nothing
        }


drawing : Id UserId -> Drawing (Id UserId)
drawing createdBy =
    { finished =
        [ { createdBy = createdBy
          , points = List.Nonempty.Nonempty ( 1.5, 2.5 ) [ ( 3, 4 ) ]
          }
        ]
    , inProgress = SeqDict.empty
    , undone = SeqDict.empty
    }
