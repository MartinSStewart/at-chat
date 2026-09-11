module ChannelExport exposing
    ( discordDmChannel
    , discordDmName
    , discordGuildChannel
    , dmChannel
    , dmFileName
    , fileName
    , guildChannel
    )

{-| Turns a channel (a guild channel, a channel belonging to a Discord guild
that we've synced, or a DM channel) into a JSON string so that the user can
download a copy of the conversation. `ChannelImport` reads the format back.

Everything that makes up the conversation is included, along with the publicly
available data (name, when they joined, and a url to their profile image) of
every member that has access to the channel. DM channels have no join times so
those are left out there.

What's left out is everything that only means something on the server the
channel came from: who was typing when, which Discord message a synced message
came from, the channel's Discord permission overwrites, and the state of any game
started in the channel. Drawings are exported as their finished strokes,
so a stroke someone is still drawing and each person's redo stack are left out
too. The key that decrypts an encrypted attachment is never exported, since
anyone the file is handed to would then be able to read it.

-}

import Array exposing (Array)
import ChannelDescription
import ChannelName exposing (ChannelName)
import Coord
import CustomEmoji
import Date exposing (Date)
import Discord
import DiscordUserData exposing (DiscordUserData)
import DmChannel exposing (BackendDmChannel, DiscordDmChannel)
import Drawing exposing (Drawing)
import Duration
import Effect.Time as Time
import Embed exposing (Embed(..))
import Emoji exposing (EmojiOrCustomEmoji(..))
import Encryption as Encrypted
import FileName
import FileStatus exposing (FileData, FileHash, FileId, FileMetadata(..), IsEncrypted(..), Orientation(..))
import GuildName
import Id exposing (Id, UserId)
import IdArray exposing (IdArray)
import Iso8601
import Json.Encode
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, BackendGuild, ChannelStatus(..), DiscordBackendChannel, DiscordBackendGuild)
import MembersAndOwner
import Message exposing (GameType(..), Message(..), UserTextMessageDrawings)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import PersonName
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import SeqSet
import User exposing (BackendUser)


{-| A file name that's safe to hand to the browser's download prompt.
-}
fileName : ChannelName -> String
fileName channelName =
    ChannelName.toString channelName |> sanitizeFileName


{-| DM channels aren't named, so they get exported under the name of the people
in them instead.
-}
dmFileName : String -> String
dmFileName dmName =
    sanitizeFileName dmName


sanitizeFileName : String -> String
sanitizeFileName text =
    (String.map
        (\char ->
            if Char.isAlphaNum char || char == '-' || char == '_' || char == ' ' then
                char

            else
                '_'
        )
        text
        |> String.trim
    )
        ++ ".json"


guildChannel : NonemptyDict (Id UserId) BackendUser -> BackendGuild -> BackendChannel -> String
guildChannel users guild channel =
    let
        ownerId : Id UserId
        ownerId =
            MembersAndOwner.owner guild.membersAndOwner

        userNames : SeqDict (Id UserId) String
        userNames =
            NonemptyDict.toSeqDict users |> SeqDict.map (\_ user -> PersonName.toString user.name)

        member : Id UserId -> Maybe Time.Posix -> Json.Encode.Value
        member userId joinedAt =
            encodeMember
                { id = Id.toString userId
                , name = SeqDict.get userId userNames |> Maybe.withDefault unknownUserName
                , joinedAt = joinedAt
                , profileImageUrl =
                    NonemptyDict.get userId users
                        |> Maybe.andThen .icon
                        |> Maybe.map profileImageUrl
                , isOwner = userId == ownerId
                }
    in
    Json.Encode.object
        [ ( "guild"
          , Json.Encode.object
                [ ( "name", Json.Encode.string (GuildName.toString guild.name) )
                , ( "createdAt", encodeTime guild.createdAt )
                ]
          )
        , ( "channel"
          , Json.Encode.object
                ([ ( "name", Json.Encode.string (ChannelName.toString channel.name) )
                 , ( "description", Json.Encode.string (ChannelDescription.toString channel.description) )
                 , ( "createdAt", encodeTime channel.createdAt )
                 , ( "createdBy", Json.Encode.string (Id.toString channel.createdBy) )
                 ]
                    ++ encodeChannelStatus channel.status
                    ++ encodeDateDividerDrawings Id.toString channel.dateDividerDrawings
                )
          )
        , ( "members"
          , member ownerId (Just guild.createdAt)
                :: (MembersAndOwner.members guild.membersAndOwner
                        |> SeqDict.toList
                        |> List.map (\( userId, data ) -> member userId (Just data.joinedAt))
                   )
                |> Json.Encode.list identity
          )
        , ( "messages"
          , encodeMessages
                Id.toString
                userNames
                (\messageId ->
                    case SeqDict.get messageId channel.threads of
                        Just thread ->
                            encodeThread Id.toString userNames thread

                        Nothing ->
                            []
                )
                channel.messages
          )
        ]
        |> Json.Encode.encode 2


discordGuildChannel :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> Discord.Id Discord.GuildId
    -> DiscordBackendGuild
    -> DiscordBackendChannel
    -> String
discordGuildChannel discordUsers guildId guild channel =
    let
        ownerId : Discord.Id Discord.UserId
        ownerId =
            MembersAndOwner.owner guild.membersAndOwner

        userNames : SeqDict (Discord.Id Discord.UserId) String
        userNames =
            SeqDict.map (\_ discordUser -> DiscordUserData.username discordUser) discordUsers

        member : Discord.Id Discord.UserId -> Maybe Time.Posix -> Json.Encode.Value
        member userId joinedAt =
            encodeMember
                { id = Discord.idToString userId
                , name = SeqDict.get userId userNames |> Maybe.withDefault unknownUserName
                , joinedAt = joinedAt
                , profileImageUrl =
                    (case SeqDict.get userId discordUsers |> Maybe.andThen DiscordUserData.icon of
                        Just fileHash ->
                            profileImageUrl fileHash

                        Nothing ->
                            Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
                    )
                        |> Just
                , isOwner = userId == ownerId
                }
    in
    Json.Encode.object
        [ ( "guild", Json.Encode.object [ ( "name", Json.Encode.string (GuildName.toString guild.name) ) ] )
        , ( "channel"
          , Json.Encode.object
                ([ ( "name", Json.Encode.string (ChannelName.toString channel.name) )
                 , ( "description", Json.Encode.string (ChannelDescription.toString channel.description) )
                 ]
                    ++ encodeChannelStatus channel.status
                    ++ encodeDateDividerDrawings Discord.idToString channel.dateDividerDrawings
                )
          )
        , ( "members"
          , member ownerId Nothing
                :: (MembersAndOwner.members guild.membersAndOwner
                        |> SeqDict.toList
                        |> List.filterMap
                            (\( userId, data ) ->
                                if LocalState.canViewDiscordChannel guildId channel guild userId then
                                    member userId data.joinedAt |> Just

                                else
                                    Nothing
                            )
                   )
                |> Json.Encode.list identity
          )
        , ( "messages"
          , encodeMessages
                Discord.idToString
                userNames
                (\messageId ->
                    case SeqDict.get messageId channel.threads of
                        Just thread ->
                            encodeThread Discord.idToString userNames thread

                        Nothing ->
                            []
                )
                channel.messages
          )
        ]
        |> Json.Encode.encode 2


{-| DM channels have no owner and no join times, so their members are only
listed by name and profile image.
-}
dmChannel : NonemptyDict (Id UserId) BackendUser -> Id UserId -> Id UserId -> BackendDmChannel -> String
dmChannel users currentUserId otherUserId channel =
    let
        userNames : SeqDict (Id UserId) String
        userNames =
            NonemptyDict.toSeqDict users |> SeqDict.map (\_ user -> PersonName.toString user.name)

        member : Id UserId -> Json.Encode.Value
        member userId =
            Json.Encode.object
                [ ( "id", Json.Encode.string (Id.toString userId) )
                , ( "name", Json.Encode.string (SeqDict.get userId userNames |> Maybe.withDefault unknownUserName) )
                , ( "profileImageUrl"
                  , NonemptyDict.get userId users
                        |> Maybe.andThen .icon
                        |> Maybe.map profileImageUrl
                        |> encodeMaybe Json.Encode.string
                  )
                ]
    in
    Json.Encode.object
        [ ( "channel"
          , Json.Encode.object
                (( "name"
                 , SeqDict.get otherUserId userNames
                    |> Maybe.withDefault unknownUserName
                    |> Json.Encode.string
                 )
                    :: encodeDateDividerDrawings Id.toString channel.dateDividerDrawings
                )
          )
        , ( "members"
          , (if currentUserId == otherUserId then
                [ member currentUserId ]

             else
                [ member currentUserId, member otherUserId ]
            )
                |> Json.Encode.list identity
          )
        , ( "messages"
          , encodeMessages
                Id.toString
                userNames
                (\messageId ->
                    case SeqDict.get messageId channel.threads of
                        Just thread ->
                            encodeThread Id.toString userNames thread

                        Nothing ->
                            []
                )
                channel.messages
          )
        ]
        |> Json.Encode.encode 2


{-| Discord DM channels don't have threads, an owner, or join times, so their
members are only listed by name and profile image.
-}
discordDmChannel :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> Discord.Id Discord.UserId
    -> DiscordDmChannel
    -> String
discordDmChannel discordUsers currentUserId channel =
    let
        userNames : SeqDict (Discord.Id Discord.UserId) String
        userNames =
            SeqDict.map (\_ discordUser -> DiscordUserData.username discordUser) discordUsers

        member : Discord.Id Discord.UserId -> Json.Encode.Value
        member userId =
            Json.Encode.object
                [ ( "id", Json.Encode.string (Discord.idToString userId) )
                , ( "name", Json.Encode.string (SeqDict.get userId userNames |> Maybe.withDefault unknownUserName) )
                , ( "profileImageUrl"
                  , (case SeqDict.get userId discordUsers |> Maybe.andThen DiscordUserData.icon of
                        Just fileHash ->
                            profileImageUrl fileHash

                        Nothing ->
                            Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
                    )
                        |> Json.Encode.string
                  )
                ]
    in
    Json.Encode.object
        [ ( "channel"
          , Json.Encode.object
                (( "name", Json.Encode.string (discordDmName discordUsers currentUserId channel) )
                    :: encodeDateDividerDrawings Discord.idToString channel.dateDividerDrawings
                )
          )
        , ( "members"
          , NonemptyDict.keys channel.members
                |> List.Nonempty.toList
                |> List.map member
                |> Json.Encode.list identity
          )
        , ( "messages", encodeMessages Discord.idToString userNames (\_ -> []) channel.messages )
        ]
        |> Json.Encode.encode 2


{-| Discord DM channels are named after everyone in them except for the user
that's viewing the channel. When the user is DMing themselves their own name is
used instead.
-}
discordDmName :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> Discord.Id Discord.UserId
    -> DiscordDmChannel
    -> String
discordDmName discordUsers currentUserId channel =
    (case List.filter (\userId -> userId /= currentUserId) (List.Nonempty.toList (NonemptyDict.keys channel.members)) of
        [] ->
            [ currentUserId ]

        otherUserIds ->
            otherUserIds
    )
        |> List.map
            (\userId ->
                case SeqDict.get userId discordUsers of
                    Just discordUser ->
                        DiscordUserData.username discordUser

                    Nothing ->
                        unknownUserName
            )
        |> String.join ", "


unknownUserName : String
unknownUserName =
    "<unknown user>"


profileImageUrl : FileHash -> String
profileImageUrl fileHash =
    FileStatus.fileUrl FileStatus.pngContent fileHash


encodeMember :
    { id : String
    , name : String
    , joinedAt : Maybe Time.Posix
    , profileImageUrl : Maybe String
    , isOwner : Bool
    }
    -> Json.Encode.Value
encodeMember data =
    Json.Encode.object
        [ ( "id", Json.Encode.string data.id )
        , ( "name", Json.Encode.string data.name )
        , ( "joinedAt", encodeMaybe encodeTime data.joinedAt )
        , ( "profileImageUrl", encodeMaybe Json.Encode.string data.profileImageUrl )
        , ( "isOwner", Json.Encode.bool data.isOwner )
        ]


{-| A thread's messages, along with anything drawn on the dividers between the days they were
written on. Both hang off the message the thread was started from.
-}
encodeThread :
    (userId -> String)
    -> SeqDict userId String
    ->
        { a
            | messages : IdArray messageId (Message messageId userId)
            , dateDividerDrawings : SeqDict Date (Drawing userId)
        }
    -> List ( String, Json.Encode.Value )
encodeThread userIdToString userNames thread =
    ( "threadMessages", encodeMessages userIdToString userNames (\_ -> []) thread.messages )
        :: drawingDictField
            "threadDateDividerDrawings"
            Date.toIsoString
            userIdToString
            thread.dateDividerDrawings


{-| The third parameter looks up the messages belonging to the thread that was
started from the message with the given id (if there is one).
-}
encodeMessages :
    (userId -> String)
    -> SeqDict userId String
    -> (Id messageId -> List ( String, Json.Encode.Value ))
    -> IdArray messageId (Message messageId userId)
    -> Json.Encode.Value
encodeMessages userIdToString userNames thread messages =
    IdArray.toList messages
        |> List.indexedMap
            (\index message -> encodeMessage userIdToString userNames (thread (Id.fromInt index)) message)
        |> Json.Encode.list identity


encodeMessage :
    (userId -> String)
    -> SeqDict userId String
    -> List ( String, Json.Encode.Value )
    -> Message messageId userId
    -> Json.Encode.Value
encodeMessage userIdToString userNames thread message =
    ((case message of
        UserTextMessage data ->
            [ ( "type", Json.Encode.string "userTextMessage" )
            , ( "createdAt", encodeTime data.createdAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.createdBy) )
            , ( "content", encodeContent userNames data.content.content )
            ]
                ++ optionalField "editedAt" encodeTime data.editedAt
                ++ optionalField
                    "repliedTo"
                    (\messageId -> Json.Encode.int (Id.toInt messageId))
                    data.repliedTo
                ++ encodeReactions userIdToString data.reactions
                ++ encodeAttachedFiles data.content.attachedFiles
                ++ encodeEmbeds data.content.embeds
                ++ encodeMessageDrawings userIdToString data.drawings

        EncryptedUserTextMessage data ->
            [ ( "encryptedData", Encrypted.encode data.content )
            , ( "type", Json.Encode.string "userTextMessage" )
            , ( "createdAt", encodeTime data.createdAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.createdBy) )
            ]
                ++ optionalField "editedAt" encodeTime data.editedAt
                ++ optionalField
                    "repliedTo"
                    (\messageId -> Json.Encode.int (Id.toInt messageId))
                    data.repliedTo
                ++ encodeReactions userIdToString data.reactions
                ++ optionalListField
                    "encryptedFileHashes"
                    (SeqSet.toList data.fileHashes
                        |> List.map (\hash -> Json.Encode.string (FileStatus.fileHashToString hash))
                    )
                ++ encodeMessageDrawings userIdToString data.drawings

        UserJoinedMessage createdAt userId reactions drawing ->
            [ ( "type", Json.Encode.string "userJoined" )
            , ( "createdAt", encodeTime createdAt )
            , ( "createdBy", Json.Encode.string (userIdToString userId) )
            ]
                ++ encodeReactions userIdToString reactions
                ++ drawingField "cardDrawing" userIdToString drawing

        DeletedMessage deletedAt ->
            [ ( "type", Json.Encode.string "deleted" )
            , ( "deletedAt", encodeTime deletedAt )
            ]

        CallStarted data ->
            [ ( "type", Json.Encode.string "callStarted" )
            , ( "createdAt", encodeTime data.startedAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.startedBy) )
            ]
                ++ optionalField "endedAt" encodeTime data.endedAt
                ++ encodeReactions userIdToString data.reactions
                ++ drawingField "timestampDrawing" userIdToString data.timestampDrawings
                ++ drawingField "cardDrawing" userIdToString data.cardDrawings

        GameStarted data ->
            [ ( "type", Json.Encode.string "gameStarted" )
            , ( "createdAt", encodeTime data.startedAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.startedBy) )
            , ( "gameType"
              , Json.Encode.string
                    (case data.gameType of
                        GameType_Go ->
                            "go"

                        GameType_WordSpellingGame ->
                            "wordSpellingGame"

                        GameType_SheepGame ->
                            "sheepGame"
                    )
              )
            ]
                ++ encodeReactions userIdToString data.reactions
                ++ drawingField "timestampDrawing" userIdToString data.timestampDrawings
                ++ drawingField "cardDrawing" userIdToString data.cardDrawings
     )
        ++ thread
    )
        |> Json.Encode.object


{-| A drawing is exported as the strokes that have been finished. A stroke someone is still
drawing and the strokes they have undone only matter while that person still has the channel
open, so they aren't part of the conversation.
-}
encodeDrawing : (userId -> String) -> Drawing userId -> Maybe Json.Encode.Value
encodeDrawing userIdToString drawing =
    case drawing.finished of
        [] ->
            Nothing

        strokes ->
            List.map
                (\stroke ->
                    Json.Encode.object
                        [ ( "createdBy", Json.Encode.string (userIdToString stroke.createdBy) )
                        , ( "points"
                          , List.Nonempty.toList stroke.points
                                |> Json.Encode.list
                                    (\( x, y ) -> Json.Encode.list Json.Encode.float [ x, y ])
                          )
                        ]
                )
                strokes
                |> Json.Encode.list identity
                |> Just


drawingField : String -> (userId -> String) -> Drawing userId -> List ( String, Json.Encode.Value )
drawingField key userIdToString drawing =
    case encodeDrawing userIdToString drawing of
        Just value ->
            [ ( key, value ) ]

        Nothing ->
            []


{-| Drawings that are attached to something there can be more than one of, such as the images
in a message, keyed by whatever they are drawn on.
-}
drawingDictField :
    String
    -> (key -> String)
    -> (userId -> String)
    -> SeqDict key (Drawing userId)
    -> List ( String, Json.Encode.Value )
drawingDictField key keyToString userIdToString drawings =
    case
        SeqDict.toList drawings
            |> List.filterMap
                (\( drawnOn, drawing ) ->
                    Maybe.map (\value -> ( keyToString drawnOn, value )) (encodeDrawing userIdToString drawing)
                )
    of
        [] ->
            []

        fields ->
            [ ( key, Json.Encode.object fields ) ]


encodeMessageDrawings :
    (userId -> String)
    -> Maybe (UserTextMessageDrawings userId)
    -> List ( String, Json.Encode.Value )
encodeMessageDrawings userIdToString maybeDrawings =
    case maybeDrawings of
        Just drawings ->
            drawingField "timestampDrawing" userIdToString drawings.timestampDrawings
                ++ drawingField "userIconDrawing" userIdToString drawings.userIconDrawings
                ++ drawingDictField
                    "imageAttachmentDrawings"
                    Id.toString
                    userIdToString
                    drawings.imageAttachmentDrawings
                ++ drawingDictField "embedDrawings" String.fromInt userIdToString drawings.embedDrawings

        Nothing ->
            []


encodeDateDividerDrawings :
    (userId -> String)
    -> SeqDict Date (Drawing userId)
    -> List ( String, Json.Encode.Value )
encodeDateDividerDrawings userIdToString drawings =
    drawingDictField "dateDividerDrawings" Date.toIsoString userIdToString drawings


{-| A channel that has been deleted is still exported, with what it took to delete it.
-}
encodeChannelStatus : ChannelStatus -> List ( String, Json.Encode.Value )
encodeChannelStatus status =
    case status of
        ChannelActive ->
            []

        ChannelDeleted { deletedAt, deletedBy } ->
            [ ( "deletedAt", encodeTime deletedAt )
            , ( "deletedBy", Json.Encode.string (Id.toString deletedBy) )
            ]


encodeContent : SeqDict userId String -> Nonempty (RichText userId) -> Json.Encode.Value
encodeContent userNames content =
    RichText.toStringWithGetter Time.utc identity False userNames content |> Json.Encode.string


encodeReactions :
    (userId -> String)
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> List ( String, Json.Encode.Value )
encodeReactions userIdToString reactions =
    SeqDict.toList reactions
        |> List.map
            (\( emoji, users ) ->
                Json.Encode.object
                    [ ( "emoji", Json.Encode.string (emojiToString emoji) )
                    , ( "users"
                      , NonemptySet.toList users
                            |> List.map userIdToString
                            |> Json.Encode.list Json.Encode.string
                      )
                    ]
            )
        |> optionalListField "reactions"


emojiToString : EmojiOrCustomEmoji -> String
emojiToString emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji unicodeEmoji ->
            Emoji.toString unicodeEmoji

        EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
            CustomEmoji.idToString customEmojiId


{-| The content type and hash are what the file is stored under, so a channel that is
imported back into the same server finds its files again. An encrypted file is exported
without the key that opens it, which is why it is marked as encrypted: whoever reads the
export can see that a file was attached without being handed the file itself.
-}
encodeAttachedFiles : SeqDict (Id FileId) FileData -> List ( String, Json.Encode.Value )
encodeAttachedFiles attachedFiles =
    SeqDict.toList attachedFiles
        |> List.map
            (\( fileId, fileData ) ->
                ([ ( "id", Json.Encode.string (Id.toString fileId) )
                 , ( "fileName", Json.Encode.string (FileName.toString fileData.fileName) )
                 , ( "fileSize", Json.Encode.int fileData.fileSize )
                 , ( "url", Json.Encode.string (FileStatus.fileDataUrl fileData) )
                 , ( "contentType", Json.Encode.int (FileStatus.contentTypeToInt fileData.contentType) )
                 , ( "fileHash", Json.Encode.string (FileStatus.fileHashToString fileData.fileHash) )
                 ]
                    ++ (case fileData.isEncrypted of
                            IsEncrypted _ _ ->
                                [ ( "isEncrypted", Json.Encode.bool True ) ]

                            IsNotEncrypted ->
                                []
                       )
                    ++ encodeFileMetadata fileData.metadata
                )
                    |> Json.Encode.object
            )
        |> optionalListField "attachedFiles"


{-| How the file is shown: its size on screen, which way up it goes, and how long a video
runs for. What the camera recorded about where and how a photo was taken stays in the file
itself, which the exported url points at.
-}
encodeFileMetadata : Maybe FileMetadata -> List ( String, Json.Encode.Value )
encodeFileMetadata metadata =
    case metadata of
        Just (FileMetadata_Image image) ->
            ( "imageSize", encodeSize image.imageSize )
                :: optionalField "orientation" encodeOrientation image.orientation

        Just (FileMetadata_Video video) ->
            [ ( "videoSize", encodeSize video.videoSize )
            , ( "orientation", encodeOrientation video.orientation )
            ]
                ++ optionalField "videoCreatedAt" encodeTime video.createdAt
                ++ optionalField
                    "durationInSeconds"
                    (\duration -> Json.Encode.float (Duration.inSeconds duration))
                    video.duration

        Nothing ->
            []


encodeSize : Coord.Coord units -> Json.Encode.Value
encodeSize size =
    Json.Encode.list Json.Encode.int [ Coord.xRaw size, Coord.yRaw size ]


encodeOrientation : Orientation -> Json.Encode.Value
encodeOrientation orientation =
    Json.Encode.string
        (case orientation of
            NoChange ->
                "noChange"

            Rotation90 ->
                "rotation90"

            Rotation180 ->
                "rotation180"

            Rotation270 ->
                "rotation270"

            Mirrored ->
                "mirrored"

            MirroredRotation90 ->
                "mirroredRotation90"

            MirroredRotation180 ->
                "mirroredRotation180"

            MirroredRotation270 ->
                "mirroredRotation270"
        )


encodeEmbeds : Array Embed -> List ( String, Json.Encode.Value )
encodeEmbeds embeds =
    Array.toList embeds
        |> List.filterMap
            (\embed ->
                case embed of
                    EmbedLoaded embedData ->
                        Json.Encode.object
                            [ ( "title", encodeMaybe Json.Encode.string embedData.title )
                            , ( "description", encodeMaybe Json.Encode.string embedData.description )
                            , ( "imageUrl", encodeMaybe (\image -> Json.Encode.string image.url) embedData.image )
                            , ( "imageSize", encodeMaybe (\image -> encodeSize image.imageSize) embedData.image )
                            , ( "createdAt", encodeMaybe encodeTime embedData.createdAt )
                            ]
                            |> Just

                    EmbedLoading ->
                        Nothing
            )
        |> optionalListField "embeds"


encodeTime : Time.Posix -> Json.Encode.Value
encodeTime time =
    Iso8601.fromTime time |> Json.Encode.string


encodeMaybe : (a -> Json.Encode.Value) -> Maybe a -> Json.Encode.Value
encodeMaybe encoder maybe =
    case maybe of
        Just a ->
            encoder a

        Nothing ->
            Json.Encode.null


{-| Most of what a message can carry (a reply, an edit, reactions, files,
embeds) is missing from the average message. Those fields are left out entirely
rather than exported as nulls and empty lists.
-}
optionalField : String -> (a -> Json.Encode.Value) -> Maybe a -> List ( String, Json.Encode.Value )
optionalField key encoder maybe =
    case maybe of
        Just a ->
            [ ( key, encoder a ) ]

        Nothing ->
            []


optionalListField : String -> List Json.Encode.Value -> List ( String, Json.Encode.Value )
optionalListField key values =
    case values of
        [] ->
            []

        _ ->
            [ ( key, Json.Encode.list identity values ) ]
