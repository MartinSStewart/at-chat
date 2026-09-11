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
import DmChannel
import Drawing exposing (Drawing)
import Emoji exposing (EmojiOrCustomEmoji(..))
import Encryption
import Expect
import Game
import Go
import Id exposing (Id, UserId)
import IdArray
import List.Nonempty
import LocalState exposing (BackendChannel, ChannelStatus(..), DiscordBackendChannel)
import Message exposing (Message(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptySet
import OneToOne
import RichText
import SeqDict
import SeqSet
import SheepGame
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
                    |> Expect.equal (Ok ( Just testChannel.name, Just testChannel.description ))
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
        , Test.test "Games come back with the moves that were played in them" <|
            \_ ->
                importedChannel
                    |> Result.map .games
                    |> Expect.equal (Ok testChannel.games)
        , Test.test "An encrypted message is imported as a deleted message and counted" <|
            \_ ->
                (case decodeExportOf { testChannel | messages = IdArray.fromList [ encryptedMessage ] } of
                    Ok channel ->
                        Ok ( IdArray.toList channel.messages, channel.encryptedMessages )

                    Err error ->
                        Err error
                )
                    |> Expect.equal (Ok ( [ DeletedMessage (time 4) ], 1 ))
        , Test.test "An encrypted message in a thread is counted too" <|
            \_ ->
                (case
                    decodeExportOf
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
                 of
                    Ok channel ->
                        Ok channel.encryptedMessages

                    Err error ->
                        Err error
                )
                    |> Expect.equal (Ok 1)
        , Test.test "A DM export is imported without a name, since a DM has none to give" <|
            \_ ->
                ChannelImport.decode (ChannelExport.dmChannel testDmChannel)
                    |> Result.map (\channel -> ( channel.name, IdArray.toList channel.messages ))
                    |> Expect.equal (Ok ( Nothing, [ textMessage ] ))
        , Test.test "A Discord channel export is turned down, since its messages belong to Discord accounts" <|
            \_ ->
                ChannelImport.decode (ChannelExport.discordGuildChannel discordChannel)
                    |> Expect.equal (Err ChannelImport.DiscordChannelsCantBeImported)
        , Test.test "A file that isn't a channel export is turned down" <|
            \_ ->
                ChannelImport.decode "not a channel export"
                    |> Result.toMaybe
                    |> Expect.equal Nothing
        ]


importedChannel : Result ChannelImport.Error ChannelImport.ImportedChannel
importedChannel =
    decodeExportOf testChannel


decodeExportOf : BackendChannel -> Result ChannelImport.Error ChannelImport.ImportedChannel
decodeExportOf channel =
    ChannelImport.decode (ChannelExport.guildChannel channel)


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
    , games =
        SeqDict.fromList [ ( Id.fromInt 0, goMatch ), ( Id.fromInt 1, sheepMatch ) ]
    }


testDmChannel : DmChannel.BackendDmChannel
testDmChannel =
    { messages = IdArray.fromList [ textMessage ]
    , lastTypedAt = SeqDict.empty
    , threads = SeqDict.empty
    , games = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , e2ee = DmChannel.E2eeDisabled Nothing
    }


{-| Discord channels are exported but not imported, so this one only needs to be something
`ChannelExport` will write out.
-}
discordChannel : DiscordBackendChannel
discordChannel =
    { name = Unsafe.channelName "general"
    , description = ChannelDescription.empty
    , isForum = False
    , messages = IdArray.empty
    , status = ChannelActive
    , lastTypedAt = SeqDict.empty
    , linkedMessageIds = OneToOne.empty
    , threads = SeqDict.empty
    , dateDividerDrawings = SeqDict.empty
    , permissionOverwrites = []
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


{-| A Go match holds nothing but its setup and its moves, so it comes back exactly as it
went in.
-}
goMatch : Game.BackendGameData
goMatch =
    Game.GameData_Go
        { width = Go.boardSize9
        , height = Go.boardSize9
        , handicap = 0
        , komiHalfPoints = Go.KomiHalfPoints 13
        , timeControl = Nothing
        , createdBy = adminId
        , gameCreatorPlayingAs = Go.Black
        }
        (Array.fromList
            [ { time = time 5, change = Go.PlaceStone 2 2 }
            , { time = time 6, change = Go.Joined otherUserId }
            , { time = time 7, change = Go.PassTurn }
            ]
        )


{-| The Sheep Game keeps the state its moves add up to alongside them. The export leaves
that out and works it out again on the way back in, the same way the backend does, so the
match this is compared against has to be built the same way.
-}
sheepMatch : Game.BackendGameData
sheepMatch =
    Game.GameData_SheepGame
        sheepSetup
        sheepActions
        (Array.foldl (SheepGame.updateAction sheepSetup) SheepGame.initShared sheepActions)


sheepSetup : SheepGame.ValidatedSetup
sheepSetup =
    { questions = List.Nonempty.Nonempty (sheepInput 'P' "ick a number") []
    , createdBy = adminId
    }


sheepActions : Array.Array SheepGame.ActionWithTime
sheepActions =
    Array.fromList
        [ { userId = otherUserId
          , time = time 8
          , change = SheepGame.SubmittedAnswer (Id.fromInt 0) (Just (sheepInput '7' ""))
          }
        , { userId = adminId, time = time 9, change = SheepGame.LockedAnswers }
        ]


sheepInput : Char -> String -> SheepGame.ValidatedInput
sheepInput first rest =
    { text =
        RichText.fromNonemptyString
            Time.utc
            (NonemptyDict.toSeqDict users)
            (String.Nonempty.NonemptyString first rest)
    , attachedFiles = SeqDict.empty
    , reactions = SeqDict.empty
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
