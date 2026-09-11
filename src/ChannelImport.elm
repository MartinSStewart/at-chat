module ChannelImport exposing (ImportedChannel, decode)

{-| Reads back the JSON that `ChannelExport` writes, so that a guild owner can turn a channel
they downloaded into a channel in their guild.

The file is read the way it was written: user ids are kept as they are, which is what makes a
channel exported and imported on the same server come back with the right people on it. A file
from somewhere else keeps its own ids, so whoever those ids belong to here is who the messages
are shown as having come from. Only a guild's owner can import a channel into it, so what the
file says is the owner's to vouch for.

Encrypted messages are left behind. The key that reads one never leaves the people in the
conversation, so there is nothing to import: each encrypted message becomes a deleted message
instead, which keeps replies and threads pointing at the messages they were written about.
Attachments that were encrypted are dropped for the same reason. Games are dropped too, since
the export only records that a game was started, not how it was played.

-}

import Array exposing (Array)
import ChannelDescription exposing (ChannelDescription)
import ChannelName exposing (ChannelName)
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import CustomEmoji
import Date exposing (Date)
import Drawing exposing (Drawing)
import Duration
import Effect.Time as Time
import Embed exposing (Embed(..))
import Emoji exposing (EmojiOrCustomEmoji(..))
import FileName
import FileStatus exposing (FileData, FileId, FileMetadata(..), IsEncrypted(..), Orientation(..))
import Id exposing (ChannelMessageId, Id, UserId)
import IdArray exposing (IdArray)
import Iso8601
import Json.Decode exposing (Decoder)
import List.Nonempty exposing (Nonempty)
import Message exposing (GameType(..), Message(..), UserTextMessageDrawings)
import NonemptySet exposing (NonemptySet)
import PersonName exposing (PersonName)
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import String.Nonempty
import Thread exposing (BackendThread)


{-| Everything an exported file has to say about the channel it came from. `encryptedMessages`
counts the messages that couldn't be brought along, so whoever imported the channel can be told
how many of them there were.
-}
type alias ImportedChannel =
    { name : ChannelName
    , description : ChannelDescription
    , createdAt : Maybe Time.Posix
    , createdBy : Maybe (Id UserId)
    , messages : IdArray ChannelMessageId (Message ChannelMessageId (Id UserId))
    , threads : SeqDict (Id ChannelMessageId) BackendThread
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    , encryptedMessages : Int
    }


decode : String -> Result Json.Decode.Error ImportedChannel
decode json =
    Json.Decode.decodeString decodeChannel json


decodeChannel : Decoder ImportedChannel
decodeChannel =
    Json.Decode.field "members" decodeMembers
        |> Json.Decode.andThen
            (\members ->
                Json.Decode.map2
                    (\channel messages ->
                        { name = channel.name
                        , description = channel.description
                        , createdAt = channel.createdAt
                        , createdBy = channel.createdBy
                        , messages = List.map .message messages |> IdArray.fromList
                        , threads =
                            List.indexedMap
                                (\index imported ->
                                    Maybe.map (\thread -> ( Id.fromInt index, thread.thread )) imported.thread
                                )
                                messages
                                |> List.filterMap identity
                                |> SeqDict.fromList
                        , dateDividerDrawings = channel.dateDividerDrawings
                        , encryptedMessages =
                            List.foldl
                                (\imported total ->
                                    total
                                        + (if imported.wasEncrypted then
                                            1

                                           else
                                            0
                                          )
                                        + (case imported.thread of
                                            Just thread ->
                                                thread.encryptedMessages

                                            Nothing ->
                                                0
                                          )
                                )
                                0
                                messages
                        }
                    )
                    (Json.Decode.field "channel" (decodeChannelFields members))
                    (Json.Decode.field "messages" (Json.Decode.list (decodeChannelMessage members)))
            )


type alias ChannelFields =
    { name : ChannelName
    , description : ChannelDescription
    , createdAt : Maybe Time.Posix
    , createdBy : Maybe (Id UserId)
    , dateDividerDrawings : SeqDict Date (Drawing (Id UserId))
    }


{-| A DM export names the channel after whoever is in it and a Discord channel has no record of
who made it or when, so everything but the name is allowed to be missing.
-}
decodeChannelFields : Members -> Decoder ChannelFields
decodeChannelFields members =
    Json.Decode.map5 ChannelFields
        (Json.Decode.field "name" Json.Decode.string
            |> Json.Decode.andThen
                (\name ->
                    case ChannelName.fromString name of
                        Ok channelName ->
                            Json.Decode.succeed channelName

                        Err error ->
                            Json.Decode.fail ("Channel name: " ++ error)
                )
        )
        (optionalField "description" Json.Decode.string
            |> Json.Decode.map
                (\description ->
                    case Maybe.map ChannelDescription.fromString description of
                        Just (Ok channelDescription) ->
                            channelDescription

                        _ ->
                            ChannelDescription.empty
                )
        )
        (optionalField "createdAt" decodeTime)
        (optionalField "createdBy" decodeUserId)
        (drawingDictField "dateDividerDrawings" dateFromString members)


type alias Members =
    SeqDict (Id UserId) { name : PersonName }


{-| The people the export lists. Message text is written with names rather than ids, so this is
what turns a name back into a mention of the person it was written for.
-}
decodeMembers : Decoder Members
decodeMembers =
    Json.Decode.list
        (Json.Decode.map2
            (\id name -> Maybe.map (\id2 -> ( id2, { name = PersonName.fromStringLossy name } )) id)
            (Json.Decode.field "id" (Json.Decode.map Id.fromString Json.Decode.string))
            (Json.Decode.field "name" Json.Decode.string)
        )
        |> Json.Decode.map (\members -> List.filterMap identity members |> SeqDict.fromList)


type alias ImportedChannelMessage =
    { message : Message ChannelMessageId (Id UserId)
    , thread : Maybe ImportedThread
    , wasEncrypted : Bool
    }


type alias ImportedThread =
    { thread : BackendThread, encryptedMessages : Int }


decodeChannelMessage : Members -> Decoder ImportedChannelMessage
decodeChannelMessage members =
    Json.Decode.map2
        (\imported thread ->
            { message = imported.message, thread = thread, wasEncrypted = imported.wasEncrypted }
        )
        (decodeMessage members)
        (decodeThread members)


{-| A thread hangs off the message it was started from, so it's read from the same object that
message is.
-}
decodeThread : Members -> Decoder (Maybe ImportedThread)
decodeThread members =
    Json.Decode.map2
        (\maybeMessages dateDividerDrawings ->
            Maybe.map
                (\messages ->
                    { thread =
                        { messages = List.map .message messages |> IdArray.fromList
                        , lastTypedAt = SeqDict.empty
                        , dateDividerDrawings = dateDividerDrawings
                        }
                    , encryptedMessages = List.filter .wasEncrypted messages |> List.length
                    }
                )
                maybeMessages
        )
        (optionalField "threadMessages" (Json.Decode.list (decodeMessage members)))
        (drawingDictField "threadDateDividerDrawings" dateFromString members)


type alias ImportedMessage messageId =
    { message : Message messageId (Id UserId), wasEncrypted : Bool }


{-| A message that couldn't be decrypted is imported as a deleted message rather than skipped.
Replies and threads point at messages by where they sit in the channel, so leaving one out
would move every message after it.
-}
decodeMessage : Members -> Decoder (ImportedMessage messageId)
decodeMessage members =
    optionalField "encryptedData" Json.Decode.value
        |> Json.Decode.andThen
            (\encryptedData ->
                case encryptedData of
                    Just _ ->
                        Json.Decode.field "createdAt" decodeTime
                            |> Json.Decode.map
                                (\createdAt -> { message = DeletedMessage createdAt, wasEncrypted = True })

                    Nothing ->
                        Json.Decode.field "type" Json.Decode.string
                            |> Json.Decode.andThen (messageOfType members)
                            |> Json.Decode.map (\message -> { message = message, wasEncrypted = False })
            )


messageOfType : Members -> String -> Decoder (Message messageId (Id UserId))
messageOfType members messageType =
    case messageType of
        "userTextMessage" ->
            decodeUserTextMessage members

        "userJoined" ->
            Json.Decode.map4
                UserJoinedMessage
                (Json.Decode.field "createdAt" decodeTime)
                (Json.Decode.field "createdBy" decodeUserId)
                (decodeReactions members)
                (drawingOrEmpty "cardDrawing" members)

        "deleted" ->
            Json.Decode.map DeletedMessage (Json.Decode.field "deletedAt" decodeTime)

        "callStarted" ->
            Json.Decode.map6
                (\startedAt startedBy endedAt reactions timestampDrawings cardDrawings ->
                    CallStarted
                        { startedAt = startedAt
                        , endedAt = endedAt
                        , startedBy = startedBy
                        , reactions = reactions
                        , timestampDrawings = timestampDrawings
                        , cardDrawings = cardDrawings
                        }
                )
                (Json.Decode.field "createdAt" decodeTime)
                (Json.Decode.field "createdBy" decodeUserId)
                (optionalField "endedAt" decodeTime)
                (decodeReactions members)
                (drawingOrEmpty "timestampDrawing" members)
                (drawingOrEmpty "cardDrawing" members)

        "gameStarted" ->
            Json.Decode.map6
                (\startedAt startedBy gameType reactions timestampDrawings cardDrawings ->
                    GameStarted
                        { startedAt = startedAt
                        , startedBy = startedBy
                        , reactions = reactions
                        , gameType = gameType
                        , timestampDrawings = timestampDrawings
                        , cardDrawings = cardDrawings
                        }
                )
                (Json.Decode.field "createdAt" decodeTime)
                (Json.Decode.field "createdBy" decodeUserId)
                (Json.Decode.field "gameType" decodeGameType)
                (decodeReactions members)
                (drawingOrEmpty "timestampDrawing" members)
                (drawingOrEmpty "cardDrawing" members)

        _ ->
            Json.Decode.fail ("Unknown message type " ++ messageType)


decodeUserTextMessage : Members -> Decoder (Message messageId (Id UserId))
decodeUserTextMessage members =
    Json.Decode.map4
        (\createdAt createdBy content extras ->
            UserTextMessage
                { createdAt = createdAt
                , createdBy = createdBy
                , content =
                    { content = content
                    , attachedFiles = extras.attachedFiles
                    , embeds = extras.embeds
                    }
                , reactions = extras.reactions
                , editedAt = extras.editedAt
                , repliedTo = extras.repliedTo
                , drawings = extras.drawings
                }
        )
        (Json.Decode.field "createdAt" decodeTime)
        (Json.Decode.field "createdBy" decodeUserId)
        (Json.Decode.field "content" (decodeContent members))
        (decodeMessageExtras members)


type alias MessageExtras messageId =
    { reactions : SeqDict EmojiOrCustomEmoji (NonemptySet (Id UserId))
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Id messageId)
    , attachedFiles : SeqDict (Id FileId) FileData
    , embeds : Array Embed
    , drawings : Maybe (UserTextMessageDrawings (Id UserId))
    }


decodeMessageExtras : Members -> Decoder (MessageExtras messageId)
decodeMessageExtras members =
    Json.Decode.map6 MessageExtras
        (decodeReactions members)
        (optionalField "editedAt" decodeTime)
        (optionalField "repliedTo" (Json.Decode.map Id.fromInt Json.Decode.int))
        (optionalField "attachedFiles" (Json.Decode.list decodeAttachedFile)
            |> Json.Decode.map
                (\files -> Maybe.withDefault [] files |> List.filterMap identity |> SeqDict.fromList)
        )
        (optionalField "embeds" (Json.Decode.list decodeEmbed)
            |> Json.Decode.map (\embeds -> Maybe.withDefault [] embeds |> Array.fromList)
        )
        (decodeMessageDrawings members)


{-| The text of a message is written the way someone would type it, so it's read back the same
way. A name that was mentioned lands on the id the export listed it under, as long as that
person is in the file's member list.
-}
decodeContent : Members -> Decoder (Nonempty (RichText (Id UserId)))
decodeContent members =
    Json.Decode.string
        |> Json.Decode.andThen
            (\text ->
                case String.Nonempty.fromString text of
                    Just nonempty ->
                        RichText.fromNonemptyString Time.utc members nonempty |> Json.Decode.succeed

                    Nothing ->
                        Json.Decode.fail "Message has no content"
            )


decodeReactions : Members -> Decoder (SeqDict EmojiOrCustomEmoji (NonemptySet (Id UserId)))
decodeReactions _ =
    optionalField
        "reactions"
        (Json.Decode.list
            (Json.Decode.map2
                (\emoji users -> Maybe.map (\users2 -> ( emoji, users2 )) (NonemptySet.fromList users))
                (Json.Decode.field "emoji" (Json.Decode.map emojiFromString Json.Decode.string))
                (Json.Decode.field "users" (Json.Decode.list decodeUserId))
            )
        )
        |> Json.Decode.map
            (\reactions -> Maybe.withDefault [] reactions |> List.filterMap identity |> SeqDict.fromList)


emojiFromString : String -> EmojiOrCustomEmoji
emojiFromString text =
    case CustomEmoji.idFromString text of
        Just customEmojiId ->
            EmojiOrCustomEmoji_CustomEmoji customEmojiId

        Nothing ->
            EmojiOrCustomEmoji_Emoji (Emoji.fromString text)


decodeGameType : Decoder GameType
decodeGameType =
    Json.Decode.string
        |> Json.Decode.andThen
            (\gameType ->
                case gameType of
                    "go" ->
                        Json.Decode.succeed GameType_Go

                    "wordSpellingGame" ->
                        Json.Decode.succeed GameType_WordSpellingGame

                    "sheepGame" ->
                        Json.Decode.succeed GameType_SheepGame

                    _ ->
                        Json.Decode.fail ("Unknown game type " ++ gameType)
            )


{-| An attachment is found again by its hash, so a channel imported on the server it was
exported from still has its files. One that was encrypted is left out: the key that opens it
isn't in the export.
-}
decodeAttachedFile : Decoder (Maybe ( Id FileId, FileData ))
decodeAttachedFile =
    Json.Decode.map7
        (\fileId fileName fileSize contentType fileHash isEncrypted metadata ->
            case ( fileId, isEncrypted ) of
                ( Just fileId2, Nothing ) ->
                    ( fileId2
                    , { fileName = FileName.fromString fileName
                      , fileSize = fileSize
                      , metadata = metadata
                      , contentType = FileStatus.contentTypeFromInt contentType
                      , fileHash = FileStatus.fileHash fileHash
                      , isEncrypted = IsNotEncrypted
                      }
                    )
                        |> Just

                _ ->
                    Nothing
        )
        (Json.Decode.field "id" (Json.Decode.map Id.fromString Json.Decode.string))
        (Json.Decode.field "fileName" Json.Decode.string)
        (Json.Decode.field "fileSize" Json.Decode.int)
        (Json.Decode.field "contentType" Json.Decode.int)
        (Json.Decode.field "fileHash" Json.Decode.string)
        (optionalField "isEncrypted" Json.Decode.bool)
        decodeFileMetadata


{-| How a file is shown: its size on screen, which way up it goes, and how long a video runs
for. What a camera recorded about where and how a photo was taken stays in the file itself,
which the export points at by url.
-}
decodeFileMetadata : Decoder (Maybe FileMetadata)
decodeFileMetadata =
    Json.Decode.map5
        (\imageSize videoSize orientation videoCreatedAt duration ->
            case ( imageSize, videoSize ) of
                ( Just size, _ ) ->
                    { imageSize = size
                    , orientation = orientation
                    , gpsLocation = Nothing
                    , cameraOwner = Nothing
                    , exposureTime = Nothing
                    , fNumber = Nothing
                    , focalLength = Nothing
                    , isoSpeedRating = Nothing
                    , make = Nothing
                    , model = Nothing
                    , software = Nothing
                    , userComment = Nothing
                    }
                        |> FileMetadata_Image
                        |> Just

                ( Nothing, Just size ) ->
                    { videoSize = size
                    , createdAt = videoCreatedAt
                    , orientation = Maybe.withDefault NoChange orientation
                    , codec = Nothing
                    , title = Nothing
                    , gpsLocation = Nothing
                    , duration = duration
                    }
                        |> FileMetadata_Video
                        |> Just

                ( Nothing, Nothing ) ->
                    Nothing
        )
        (optionalField "imageSize" decodeSize)
        (optionalField "videoSize" decodeSize)
        (optionalField "orientation" decodeOrientation)
        (optionalField "videoCreatedAt" decodeTime)
        (optionalField "durationInSeconds" (Json.Decode.map Duration.seconds Json.Decode.float))


{-| A link preview keeps what it showed. Its picture is pointed at by url, which is how it was
loaded in the first place, so a preview still has one wherever the channel is imported.
-}
decodeEmbed : Decoder Embed
decodeEmbed =
    Json.Decode.map5
        (\title description imageUrl imageSize createdAt ->
            EmbedLoaded
                { title = title
                , description = description
                , image =
                    case ( imageUrl, imageSize ) of
                        ( Just url, Just size ) ->
                            Just { url = url, imageSize = size, format = Nothing }

                        _ ->
                            Nothing
                , createdAt = createdAt
                }
        )
        (nullableField "title" Json.Decode.string)
        (nullableField "description" Json.Decode.string)
        (nullableField "imageUrl" Json.Decode.string)
        (nullableField "imageSize" decodeSize)
        (nullableField "createdAt" decodeTime)


decodeMessageDrawings : Members -> Decoder (Maybe (UserTextMessageDrawings (Id UserId)))
decodeMessageDrawings members =
    Json.Decode.map4
        (\timestampDrawings userIconDrawings imageAttachmentDrawings embedDrawings ->
            if
                (timestampDrawings == Nothing)
                    && (userIconDrawings == Nothing)
                    && SeqDict.isEmpty imageAttachmentDrawings
                    && SeqDict.isEmpty embedDrawings
            then
                Nothing

            else
                { timestampDrawings = Maybe.withDefault Drawing.emptyDrawing timestampDrawings
                , userIconDrawings = Maybe.withDefault Drawing.emptyDrawing userIconDrawings
                , imageAttachmentDrawings = imageAttachmentDrawings
                , embedDrawings = embedDrawings
                }
                    |> Just
        )
        (optionalField "timestampDrawing" (decodeDrawing members))
        (optionalField "userIconDrawing" (decodeDrawing members))
        (drawingDictField "imageAttachmentDrawings" Id.fromString members)
        (drawingDictField "embedDrawings" String.toInt members)


dateFromString : String -> Maybe Date
dateFromString text =
    Date.fromIsoString text |> Result.toMaybe


drawingOrEmpty : String -> Members -> Decoder (Drawing (Id UserId))
drawingOrEmpty key members =
    optionalField key (decodeDrawing members)
        |> Json.Decode.map (Maybe.withDefault Drawing.emptyDrawing)


drawingDictField : String -> (String -> Maybe key) -> Members -> Decoder (SeqDict key (Drawing (Id UserId)))
drawingDictField field keyFromString members =
    optionalField field (Json.Decode.keyValuePairs (decodeDrawing members))
        |> Json.Decode.map
            (\drawings ->
                Maybe.withDefault [] drawings
                    |> List.filterMap
                        (\( key, drawing ) -> Maybe.map (\key2 -> ( key2, drawing )) (keyFromString key))
                    |> SeqDict.fromList
            )


{-| Only finished strokes are exported, so a drawing comes back with nothing part way through
and nothing to redo.
-}
decodeDrawing : Members -> Decoder (Drawing (Id UserId))
decodeDrawing _ =
    Json.Decode.list
        (Json.Decode.map2
            (\createdBy points ->
                Maybe.map
                    (\points2 -> { createdBy = createdBy, points = points2 })
                    (List.Nonempty.fromList points)
            )
            (Json.Decode.field "createdBy" decodeUserId)
            (Json.Decode.field "points" (Json.Decode.list decodePoint))
        )
        |> Json.Decode.map
            (\strokes ->
                { finished = List.filterMap identity strokes
                , inProgress = SeqDict.empty
                , undone = SeqDict.empty
                }
            )


decodePoint : Decoder ( Float, Float )
decodePoint =
    Json.Decode.list Json.Decode.float
        |> Json.Decode.andThen
            (\point ->
                case point of
                    [ x, y ] ->
                        Json.Decode.succeed ( x, y )

                    _ ->
                        Json.Decode.fail "Expected a point to be an x and a y"
            )


decodeSize : Decoder (Coord CssPixels)
decodeSize =
    Json.Decode.list Json.Decode.int
        |> Json.Decode.andThen
            (\size ->
                case size of
                    [ width, height ] ->
                        Json.Decode.succeed (Coord.xy width height)

                    _ ->
                        Json.Decode.fail "Expected a size to be a width and a height"
            )


decodeOrientation : Decoder Orientation
decodeOrientation =
    Json.Decode.string
        |> Json.Decode.andThen
            (\orientation ->
                case orientation of
                    "noChange" ->
                        Json.Decode.succeed NoChange

                    "rotation90" ->
                        Json.Decode.succeed Rotation90

                    "rotation180" ->
                        Json.Decode.succeed Rotation180

                    "rotation270" ->
                        Json.Decode.succeed Rotation270

                    "mirrored" ->
                        Json.Decode.succeed Mirrored

                    "mirroredRotation90" ->
                        Json.Decode.succeed MirroredRotation90

                    "mirroredRotation180" ->
                        Json.Decode.succeed MirroredRotation180

                    "mirroredRotation270" ->
                        Json.Decode.succeed MirroredRotation270

                    _ ->
                        Json.Decode.fail ("Unknown orientation " ++ orientation)
            )


{-| An id this server doesn't know is still kept. The export is a record of who wrote what, and
dropping the ids this server can't put a name to would lose that.
-}
decodeUserId : Decoder (Id UserId)
decodeUserId =
    Json.Decode.string
        |> Json.Decode.andThen
            (\text ->
                case Id.fromString text of
                    Just userId ->
                        Json.Decode.succeed userId

                    Nothing ->
                        Json.Decode.fail ("Not a user id: " ++ text)
            )


decodeTime : Decoder Time.Posix
decodeTime =
    Json.Decode.string
        |> Json.Decode.andThen
            (\text ->
                case Iso8601.toTime text of
                    Ok time ->
                        Json.Decode.succeed time

                    Err _ ->
                        Json.Decode.fail ("Not a time: " ++ text)
            )


{-| A field the export leaves out when there is nothing to say.
-}
optionalField : String -> Decoder a -> Decoder (Maybe a)
optionalField key decoder =
    Json.Decode.oneOf
        [ Json.Decode.field key (Json.Decode.map Just decoder)
        , Json.Decode.succeed Nothing
        ]


{-| A field the export writes as null when there is nothing to say.
-}
nullableField : String -> Decoder a -> Decoder (Maybe a)
nullableField key decoder =
    optionalField key (Json.Decode.nullable decoder) |> Json.Decode.map (Maybe.andThen identity)
