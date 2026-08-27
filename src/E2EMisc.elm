module E2EMisc exposing
    ( channelSearchTest
    , codeBlockInputTest
    , colorPickerTest
    , dmThreadsTest
    , emojiSuggestionTest
    , endToEndEncryptionAcceptTest
    , endToEndEncryptionRequestTest
    , exportChannelTest
    , exportDmChannelTest
    , friendsSearchTest
    , inactiveDmThreadsAreHiddenTest
    , inactiveThreadsAreHiddenTest
    , inviteUserAndDmChat
    , largePasteBecomesAttachment
    , leaveGuildTest
    , markMessageAsUnreadTest
    , mentionSuggestionTest
    , noTimestampSuggestionTest
    , profileImageOpensDm
    , reactionPopupNamesEmojiTest
    , reloadingAConversationLeavesItUnreadTest
    , startingACallOrGameStaysReadTest
    , staysReadWhileViewingTest
    , swipedAwayConversationStopsBeingViewedTest
    , timeOfDaySuggestionTest
    , timeOffsetSuggestionTest
    )

import Audio
import Base64
import Broadcast
import DmChannel
import DmChannelId
import Duration
import E2EHelper
import E2EVoiceChat
import Effect.Browser.Dom as Dom
import Effect.Lamdera as Lamdera
import Effect.Test as T
import Effect.Time as Time
import Emoji
import Encryption
import Expect
import FileStatus
import Html.Attributes
import Id
import IdArray
import Json.Encode
import List.Nonempty
import Local
import LocalState exposing (LocalState)
import MembersAndOwner
import Message
import NonemptyDict
import Pages.Guild
import RichText
import Route exposing (ChannelsVisibleOnMobile(..))
import SeqDict
import String.Nonempty
import Test.Html.Query
import Test.Html.Selector
import TimeInMinutes
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import UserColor
import UserSession
import X25519


{-| Pasting a large chunk of text that would push the message over the max message length converts the pasted text into a text file attachment instead of inserting it into the text input.
-}
largePasteBecomesAttachment :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
largePasteBecomesAttachment config =
    E2EHelper.startTest
        "Pasted text too long to fit in a message is attached as a text file instead"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                let
                    pastedText : String
                    pastedText =
                        String.repeat 250 "0123456789"
                in
                [ E2EHelper.focusEvent admin 1000 (Just (Dom.id "channel_textinput")) (Just { start = 0, end = 0 })
                , admin.click 100 (Dom.id "channel_textinput")
                , admin.input 100 (Dom.id "channel_textinput") "Check this out! "
                , admin.input 100 (Dom.id "channel_textinput") ("Check this out! " ++ pastedText)

                -- The pasted text is removed from the draft and replaced with an attached file placeholder
                , T.checkState
                    100
                    (\data ->
                        case SeqDict.get admin.clientId data.frontends |> Maybe.map Audio.userModel of
                            Just (Types.Loaded loaded) ->
                                case loaded.loginStatus of
                                    Types.LoggedIn loggedIn ->
                                        if
                                            List.map
                                                String.Nonempty.toString
                                                (SeqDict.values loggedIn.drafts)
                                                == [ "Check this out! [!1]" ]
                                        then
                                            Ok ()

                                        else
                                            Err "The pasted text should have been replaced with a file attachment placeholder in the draft"

                                    Types.NotLoggedIn _ ->
                                        Err "Expected admin to be logged in"

                            _ ->
                                Err "Expected admin frontend to be loaded"
                    )

                -- The Rust server tells the backend about the uploaded file (in tests the
                -- upload HTTP response is mocked so this notification is injected manually,
                -- like E2EHelper.uploadNonImageAttachment does).
                , T.backendUpdate
                    100
                    (Types.Rpc_GotFileUpload (FileStatus.fileHash "123123123") 2500 Nothing)
                , admin.keyDown 1000 (Dom.id "channel_textinput") "Enter" []
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "guild_message_1" ]
                    )
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "message.txt" ])
                ]
            )
        ]


{-| Hovering a message shows a popup above each of its reactions naming who reacted.
For a standard unicode emoji the popup also names the emoji itself, which it can only
do once the emoji data has been fetched and copied into LocalUser.
-}
reactionPopupNamesEmojiTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
reactionPopupNamesEmojiTest config =
    E2EHelper.startTest
        "Hovering a reaction names the emoji it was made with"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.writeMessage admin 1000 "Hello everyone"

                -- The first of the buttons that appear when hovering a message reacts
                -- with ❤️, the emoji `User.commonlyUsedEmojis` leads with.
                , admin.mouseEnter 100 (Dom.id "guild_message_1") ( 10, 10 ) []
                , admin.click 100 (Dom.id "miniView_emojiReact_0")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_removeReactionEmoji_0" ])
                , admin.mouseEnter 100 (Dom.id "guild_message_1") ( 10, 10 ) []
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.class "emoji-popup"
                        , Test.Html.Selector.text ":heart:"
                        ]
                    )
                ]
            )
        ]


{-| Pressing "Export channel" in the member column asks the backend for a JSON
copy of the channel and downloads it. The JSON should contain every message plus
the publicly available data of everyone with access to the channel.
-}
exportChannelTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
exportChannelTest config =
    E2EHelper.startTest
        "Export a guild channel to a JSON file"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.writeMessage admin 1000 "Hello everyone"
                , admin.click 1000 (Dom.id "guild_showMembers")
                , admin.click 1000 (Dom.id "guild_exportChannel")
                , T.checkState
                    1000
                    (\data ->
                        case data.downloads of
                            [ download ] ->
                                case download.content of
                                    T.StringFile content ->
                                        case
                                            List.filter
                                                (\text -> not (String.contains text content))
                                                [ "Hello everyone", "\"" ++ E2EHelper.adminName ++ "\"", "Stevie Steve" ]
                                        of
                                            [] ->
                                                -- None of these messages were replied to, edited,
                                                -- reacted to or given files, so those fields should
                                                -- be left out instead of exported as nulls and
                                                -- empty lists.
                                                case
                                                    List.filter
                                                        (\text -> String.contains text content)
                                                        [ "\"editedAt\""
                                                        , "\"repliedTo\""
                                                        , "\"reactions\""
                                                        , "\"attachedFiles\""
                                                        , "\"embeds\""
                                                        ]
                                                of
                                                    [] ->
                                                        Ok ()

                                                    empty ->
                                                        Err
                                                            ("Empty fields in the exported JSON: "
                                                                ++ String.join ", " empty
                                                            )

                                            missing ->
                                                Err ("Missing from the exported JSON: " ++ String.join ", " missing)

                                    T.BytesFile _ ->
                                        Err "The exported channel should be a text file"

                            downloads ->
                                Err
                                    ("Expected a single download, instead got "
                                        ++ String.fromInt (List.length downloads)
                                    )
                    )
                ]
            )
        ]


{-| DM channels have a member column too, listing the two people in the DM and
the same "Export channel" button that guild channels have.
-}
exportDmChannelTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
exportDmChannelTest config =
    E2EHelper.startTest
        "Export a DM channel to a JSON file"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.openDm user 1000 "0"
                        , E2EHelper.writeMessage user 100 "Hello in a DM"
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Members (2)" ])
                        , user.click 100 (Dom.id "guild_showMembers")
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "Members (2)" ])
                        , user.click 1000 (Dom.id "guild_exportChannel")
                        , T.checkState
                            1000
                            (\data ->
                                case data.downloads of
                                    [ download ] ->
                                        case download.content of
                                            T.StringFile content ->
                                                case
                                                    List.filter
                                                        (\text -> not (String.contains text content))
                                                        [ "Hello in a DM", "\"" ++ E2EHelper.adminName ++ "\"", "\"Sven\"" ]
                                                of
                                                    [] ->
                                                        Ok ()

                                                    missing ->
                                                        Err ("Missing from the exported JSON: " ++ String.join ", " missing)

                                            T.BytesFile _ ->
                                                Err "The exported channel should be a text file"

                                    downloads ->
                                        Err
                                            ("Expected a single download, instead got "
                                                ++ String.fromInt (List.length downloads)
                                            )
                            )
                        ]
                    )
                ]
            )
        ]


{-| The two people in a DM both have to accept the risks that come with end-to-end
encryption before it can be turned on, so asking for it leaves the asker waiting and puts
the request in front of the other person.
-}
endToEndEncryptionRequestTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
endToEndEncryptionRequestTest config =
    let
        warning : String
        warning =
            "If you lose it, you'll permanently lose access to all your encrypted messages."
    in
    E2EHelper.startTest
        "Ask the other person in a DM to start end-to-end encryption"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.openDm admin 100 "2"
                , E2EHelper.openDm user 100 "0"
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.text "End-to-end encryption" ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text warning ])
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text warning ])
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text "Enable end-to-end encryption" ])
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")

                -- Encrypting anything needs a key pair on the account first, so that
                -- stands in front of enabling it.
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text "Enable end-to-end encryption" ])
                , addPrivateKeyToAccount admin
                    (\_ ->
                        [ admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "Enable end-to-end encryption" ])
                        , admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "Enable end-to-end encryption" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text "Waiting for Stevie Steve to accept message encryption."
                                , Test.Html.Selector.id "guild_cancelE2ee"
                                ]
                            )
                        , E2EHelper.checkNotification E2EHelper.adminName "Wants to start end-to-end encryption"
                        , user.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute
                                    (Html.Attributes.attribute
                                        "aria-label"
                                        "Waiting for an answer about end-to-end encryption"
                                    )
                                ]
                            )

                        -- The request opens the section on its own, so the warning is waiting for
                        -- them as soon as they open the channel settings.
                        , user.click 100 (Dom.id "guild_showMembers")
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text warning ])
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "Start end-to-end encryption" ])
                        , user.click 100 (Dom.id "guild_e2eeAcceptRisks")
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "to start encrypting this conversation" ])
                        , addPrivateKeyToAccount user
                            (\_ ->
                                [ user.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "to start encrypting this conversation" ]
                                    )
                                , T.checkBackend 100 checkBothKeysStoredAndDifferent
                                , admin.click 100 (Dom.id "guild_cancelE2ee")
                                , user.checkView
                                    100
                                    (Test.Html.Query.hasNot
                                        [ Test.Html.Selector.text "to start encrypting this conversation" ]
                                    )
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "Enable end-to-end encryption" ]
                                    )

                                -- Accepting the risks is answered once for the account rather than once
                                -- per conversation, so a DM that has never been opened before starts out
                                -- past that step instead of asking again. Reaching one means going back
                                -- out through the guild, since the buttons that open a DM live in a guild
                                -- channel's member list.
                                , admin.click 100 (Dom.id "guild_hideMembers")
                                , admin.click 100 (Dom.id "guild_openGuild_0")
                                , admin.click 100 (Dom.id "guild_openChannel_0")
                                , E2EHelper.openDm admin 100 "0"
                                , admin.click 100 (Dom.id "guild_showMembers")
                                , admin.click 100 (Dom.id "guild_e2eeSection")
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text warning
                                        , Test.Html.Selector.text "Enable end-to-end encryption"
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]


{-| Accepting a request is what actually turns encryption on: both people work out the
same shared secret from their own private key and the other's public one, hand it to the
browser to keep, and from then on messages go through the browser before they are sent.
-}
endToEndEncryptionAcceptTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
endToEndEncryptionAcceptTest config =
    E2EHelper.startTest
        "Accept an encryption request and send an encrypted message"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.openDm admin 100 "2"
                , E2EHelper.openDm user 100 "0"

                -- The person asking sets themselves up and sends the request.
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.click 100 (Dom.id "guild_enableE2ee")

                        -- The person being asked accepts by typing their private key in,
                        -- which is the point at which their browser is given a key.
                        , user.click 100 (Dom.id "guild_showMembers")
                        , user.click 100 (Dom.id "guild_e2eeAcceptRisks")
                        , addPrivateKeyToAccount user
                            (\userPrivateKey ->
                                [ -- Part of a key is not a key. Nothing should happen
                                  -- until the whole thing has arrived, which is what the
                                  -- trailing "=" says, so that a password manager typing
                                  -- it one character at a time still works.
                                  user.input 100 (Dom.id "guild_e2eePrivateKey") (String.dropRight 5 userPrivateKey)
                                , T.checkState 100 (checkNoSharedSecretsYet 0)
                                , user.input 100 (Dom.id "guild_e2eePrivateKey") userPrivateKey
                                , E2EHelper.respondToEncryptionPort user

                                -- Accepting reaches the other side, but the private key
                                -- was never kept, so that side has to be asked for it too.
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "This device doesn't have the key" ]
                                    )
                                , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                                , E2EHelper.respondToEncryptionPort admin
                                , T.checkState 100 checkBothSidesDerivedTheSameSecret
                                , T.checkBackend 100 checkDmIsEncrypted
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "E2EE was enabled on" ])

                                -- The section opens itself only while an answer is being
                                -- waited on, so once given it closes and must be reopened.
                                , user.click 100 (Dom.id "guild_e2eeSection")
                                , user.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "E2EE was enabled on" ])

                                -- A message in an encrypted conversation goes past the
                                -- browser first, and what reaches the server is what came
                                -- back rather than what was typed.
                                , admin.click 100 (Dom.id "guild_hideMembers")
                                , E2EHelper.writeMessage admin 100 "Hello in secret"
                                , T.checkBackend 100 (checkNoPlainTextReachedTheServer "Hello in secret")
                                , E2EHelper.respondToEncryptionPort admin
                                , T.checkBackend 100 (checkEncryptedMessageStored "Hello in secret")

                                -- Without a key on this device the message is not sent,
                                -- and the draft is left alone so nothing is lost.
                                , E2EHelper.writeMessage admin 100 "This one cannot go"
                                , E2EHelper.respondToEncryptionPortWithMissingKey admin
                                , T.checkBackend 100 (checkEncryptedMessageCount 1)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text "This one cannot go" ])
                                ]
                            )
                        ]
                    )
                ]
            )
        ]


{-| How many shared secrets have been handed to a browser so far. Used to check that a
partly typed key does nothing at all.
-}
checkNoSharedSecretsYet : Int -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkNoSharedSecretsYet expected data =
    let
        actual : Int
        actual =
            List.length (storedSharedSecrets data)
    in
    if actual == expected then
        Ok ()

    else
        Err
            ("Expected "
                ++ String.fromInt expected
                ++ " shared secrets to have been worked out by now, found "
                ++ String.fromInt actual
            )


storedSharedSecrets : T.Data FrontendModel E2EHelper.BackendModel2 -> List String
storedSharedSecrets data =
    SeqDict.keys data.frontends
        |> List.concatMap (\clientId -> E2EHelper.encryptionPortRequests clientId data)
        |> List.filterMap
            (\request ->
                case request of
                    Encryption.ToJs_StoreSharedSecret { sharedSecret } ->
                        Just sharedSecret

                    Encryption.ToJs_EncryptMessage _ ->
                        Nothing

                    Encryption.ToJs_CheckKey _ ->
                        Nothing
            )


{-| Both people should have handed the browser the same secret. They each work it out
from their own private key and the other's public one, so this failing means the key
agreement disagreed across the two clients.
-}
checkBothSidesDerivedTheSameSecret : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkBothSidesDerivedTheSameSecret data =
    let
        secrets : List String
        secrets =
            storedSharedSecrets data
    in
    case secrets of
        [ first, second ] ->
            if first == second then
                Ok ()

            else
                Err "The two sides worked out different shared secrets"

        _ ->
            Err
                ("Expected both sides to store a shared secret, instead got "
                    ++ String.fromInt (List.length secrets)
                )


checkDmIsEncrypted : E2EHelper.BackendModel2 -> Result String ()
checkDmIsEncrypted backend =
    case adminDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeEnabled _) ->
            Ok ()

        _ ->
            Err "The DM should have been marked as encrypted on the backend"


{-| The server should never have been handed the message as it was typed.
-}
checkNoPlainTextReachedTheServer : String -> E2EHelper.BackendModel2 -> Result String ()
checkNoPlainTextReachedTheServer text backend =
    if List.any (String.contains text) (encryptedMessageContents backend) then
        Err "The message reached the server as plain text"

    else
        Ok ()


checkEncryptedMessageStored : String -> E2EHelper.BackendModel2 -> Result String ()
checkEncryptedMessageStored text backend =
    let
        expected : String
        expected =
            Base64.fromString text |> Maybe.withDefault "not base64"
    in
    if List.member expected (encryptedMessageContents backend) then
        Ok ()

    else
        Err
            ("The stored message isn't what the browser handed back. Stored: "
                ++ String.join ", " (encryptedMessageContents backend)
            )


checkEncryptedMessageCount : Int -> E2EHelper.BackendModel2 -> Result String ()
checkEncryptedMessageCount expected backend =
    let
        actual : Int
        actual =
            List.length (encryptedMessageContents backend)
    in
    if actual == expected then
        Ok ()

    else
        Err
            ("Expected "
                ++ String.fromInt expected
                ++ " encrypted messages on the backend, found "
                ++ String.fromInt actual
            )


encryptedMessageContents : E2EHelper.BackendModel2 -> List String
encryptedMessageContents backend =
    case adminDmChannel backend of
        Just dmChannel ->
            IdArray.toList dmChannel.messages
                |> List.filterMap
                    (\message ->
                        case message of
                            Message.EncryptedUserTextMessage data ->
                                Just (Encryption.toBase64 data.content)

                            _ ->
                                Nothing
                    )

        Nothing ->
            []


adminDmChannel : E2EHelper.BackendModel2 -> Maybe DmChannel.DmChannel
adminDmChannel backend =
    SeqDict.get
        (DmChannelId.fromUserIds (Id.fromInt 0) (Id.fromInt 2))
        (E2EHelper.unwrapBackend backend).dmChannels


{-| Generates a key pair, which stores the public half on the account and shows the
private half once. The showing is checked on the way past, since it is the only chance
anybody gets to save the key.
-}
addPrivateKeyToAccount :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> (String -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
addPrivateKeyToAccount client continueWith =
    T.group
        [ client.click 100 (Dom.id "guild_addPrivateKey")
        , client.checkView
            100
            (Test.Html.Query.has
                [ Test.Html.Selector.text "Save your private key now"
                , Test.Html.Selector.text "It is not stored anywhere else"
                , Test.Html.Selector.id "frontend_newPrivateKey_copy"
                ]
            )
        , T.andThen
            100
            (\data ->
                case privateKeyOnScreen client.clientId data of
                    Just privateKeyText ->
                        client.click 100 (Dom.id "frontend_closeNewPrivateKey")
                            :: client.checkView
                                100
                                (Test.Html.Query.hasNot
                                    [ Test.Html.Selector.text "Save your private key now" ]
                                )
                            :: continueWith privateKeyText

                    Nothing ->
                        [ T.checkState 0 (\_ -> Err "The private key wasn't on screen to be read") ]
            )
        ]


{-| Reads the private key out of the popup while it is up. The app forgets it the moment
that closes, so this is the only chance a test gets to hold onto it either, which is the
same position the person using it is in.
-}
privateKeyOnScreen : Lamdera.ClientId -> T.Data FrontendModel E2EHelper.BackendModel2 -> Maybe String
privateKeyOnScreen clientId data =
    case SeqDict.get clientId data.frontends |> Maybe.map Audio.userModel of
        Just (Types.Loaded loaded) ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    Maybe.map X25519.privateKeyToString loggedIn.showNewPrivateKey

                Types.NotLoggedIn _ ->
                    Nothing

        _ ->
            Nothing


{-| Both accounts should have ended up with a public key, and crucially not the same one:
they are generated from the random words each client started with, so a shared seed would
quietly give two people the same private key.
-}
checkBothKeysStoredAndDifferent : E2EHelper.BackendModel2 -> Result String ()
checkBothKeysStoredAndDifferent backend =
    let
        keyOf : Int -> Maybe X25519.PublicKey
        keyOf userId =
            NonemptyDict.get (Id.fromInt userId) (E2EHelper.unwrapBackend backend).users
                |> Maybe.andThen .publicKey
    in
    case ( keyOf 0, keyOf 2 ) of
        ( Just adminKey, Just userKey ) ->
            if adminKey == userKey then
                Err "Both accounts ended up with the same public key"

            else
                Ok ()

        ( Nothing, _ ) ->
            Err "The admin's public key wasn't stored on the backend"

        ( _, Nothing ) ->
            Err "The user's public key wasn't stored on the backend"


{-| Simulates the browser moving focus into a search input. Unlike
`E2EHelper.focusEvent` this includes the `selectionDirection` field, which the
focus decoder requires before it will record the input as focused.
-}
focusSearchInput :
    Dom.HtmlId
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
focusSearchInput htmlId client =
    client.portEvent
        100
        "focus_changed_from_js"
        (Json.Encode.object
            [ ( "id", Json.Encode.string (Dom.idToString htmlId) )
            , ( "selectionStart", Json.Encode.int 0 )
            , ( "selectionEnd", Json.Encode.int 0 )
            , ( "selectionDirection", Json.Encode.string "forward" )
            ]
        )


friendsSearchTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
friendsSearchTest config =
    E2EHelper.startTest
        "Filter friends with the direct messages search input"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.openDm user 1000 "0"
                        , E2EHelper.writeMessage user 100 "Hello admin!"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.openDm admin 100 "2"

                        -- The search input is transparent until it gets focus, so its placeholder
                        -- text is used to detect whether it is shown or not.
                        , admin.checkView 100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.id "guild_friendLabel_0"
                                , Test.Html.Selector.id "guild_friendLabel_2"
                                , Test.Html.Selector.exactText "Direct messages"
                                ]
                            )
                        , admin.checkView 100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends") ]
                            )
                        , focusSearchInput Pages.Guild.friendsSearchInputId admin
                        , admin.checkView 100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends") ]
                            )
                        , admin.snapshotView 100 { name = "Friends search input open" }
                        , admin.input 100 Pages.Guild.friendsSearchInputId "sven"
                        , admin.checkView 100
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_friendLabel_2" ])
                        , admin.checkView 100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_friendLabel_0" ])
                        , admin.snapshotView 100 { name = "Friends search input filters friends column" }
                        , admin.input 100 Pages.Guild.friendsSearchInputId "does not match anyone"
                        , admin.checkView 100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_friendLabel_2" ])

                        -- Clearing the text shows all friends again, and the input stays visible
                        -- because it still has focus.
                        , admin.click 100 (Dom.id "guild_clearFriendsSearch")
                        , admin.checkView 100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.id "guild_friendLabel_0"
                                , Test.Html.Selector.id "guild_friendLabel_2"
                                , Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends")
                                ]
                            )

                        -- Once the empty input loses focus it becomes transparent again.
                        , E2EHelper.focusEvent admin 100 Nothing Nothing
                        , admin.checkView 100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.attribute (Html.Attributes.placeholder "Filter friends") ]
                            )
                        ]
                    )
                ]
            )
        ]


channelSearchTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
channelSearchTest config =
    E2EHelper.startTest
        "Filter channels with the channel column search input"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 100 (Dom.id "guild_createGuild")
                , admin.input 100 (Dom.id "newGuildName") "My new guild!"
                , admin.click 100 (Dom.id "guild_createGuildSubmit")

                -- The search row only appears for guilds with more than 6 channels.
                , admin.checkView 100
                    (Test.Html.Query.hasNot
                        [ Test.Html.Selector.id (Dom.idToString Pages.Guild.channelSearchInputId) ]
                    )
                , List.map
                    (\channelName ->
                        T.group
                            [ admin.click 100 (Dom.id "guild_newChannel")
                            , admin.input 100 (Dom.id "newChannelName") channelName
                            , admin.click 100 (Dom.id "guild_createChannel")
                            ]
                    )
                    [ "alpha", "beta", "gamma", "delta", "epsilon", "zeta" ]
                    |> T.group

                -- With 7 channels the search row appears below the header.
                , admin.checkView 100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id (Dom.idToString Pages.Guild.channelSearchInputId)
                        , Test.Html.Selector.attribute (Html.Attributes.placeholder "Search channels")
                        ]
                    )
                , admin.snapshotView 100 { name = "Channel search row in channel column" }
                , admin.input 100 Pages.Guild.channelSearchInputId "zeta"
                , admin.checkView 100
                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_openChannel_6" ])
                , admin.checkView 100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_openChannel_0" ])
                , admin.snapshotView 100 { name = "Channel search row filters channel column" }
                , admin.input 100 Pages.Guild.channelSearchInputId "does not match any channel"
                , admin.checkView 100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_openChannel_6" ])
                , admin.checkView 100
                    (Test.Html.Query.has [ Test.Html.Selector.exactText "No matching channels\u{00A0}found" ])

                -- Clearing the text shows all channels again.
                , admin.click 100 (Dom.id "guild_clearChannelSearch")
                , admin.checkView 100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "guild_openChannel_0"
                        , Test.Html.Selector.id "guild_openChannel_6"
                        , Test.Html.Selector.attribute (Html.Attributes.placeholder "Search channels")
                        ]
                    )
                ]
            )
        ]


inviteUserAndDmChat : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
inviteUserAndDmChat config =
    E2EHelper.startTest
        "Invite user and then have DM chat"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.openDm user 1000 "0"
                        , E2EHelper.writeMessage user 100 "Hello"
                        , admin.click 100 (Dom.id "guildsColumn_openDm_2")
                        , E2EHelper.writeMessage user 100 "Hello 2"
                        , E2EHelper.writeMessage admin 100 "Hello from *admin*"
                        , user.checkView
                            100
                            (\html ->
                                Test.Html.Query.findAll [ Test.Html.Selector.exactText "Sven" ] html
                                    -- Two Sven messages, Sven in the DM column, and Sven in the user options
                                    |> Test.Html.Query.count (Expect.equal 4)
                            )
                        , E2EHelper.createThread user (Id.fromInt 1)
                        , E2EHelper.writeMessage user 100 "Writing in thread"
                        , admin.checkView
                            100
                            (\html ->
                                Test.Html.Query.find [ Test.Html.Selector.id "guild_threadStarterIndicator_1" ] html
                                    |> Test.Html.Query.has
                                        [ Test.Html.Selector.containing [ Test.Html.Selector.exactText "Sven" ]
                                        ]
                            )
                        , admin.click 100 (Dom.id "guild_threadStarterIndicator_1")
                        ]
                    )
                ]
            )
        ]


{-| Clicking the profile image next to a message in a guild channel opens the DM channel
with whoever wrote it.
-}
profileImageOpensDm : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
profileImageOpensDm config =
    E2EHelper.startTest
        "Clicking a profile image opens the DM channel with that user"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.writeMessage user 100 "Click on my profile image!"
                , T.andThen
                    100
                    (\data ->
                        case E2EHelper.lastGuildChannelMessage data.backend of
                            Just ( _, messageId, Message.UserTextMessage message ) ->
                                [ admin.click 100 (Pages.Guild.profileImageButtonId messageId)
                                , admin.checkModel 100 (checkDmRouteWithUser message.createdBy)
                                ]

                            _ ->
                                [ admin.checkModel
                                    100
                                    (\_ -> Err "Expected the guild channel to contain the other user's message")
                                ]
                    )
                ]
            )
        ]


checkDmThreadRoute : Id.Id Id.ChannelMessageId -> FrontendModel -> Result String ()
checkDmThreadRoute threadMessageIndex model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.route of
                Route.DmRoute dmRoute ->
                    case dmRoute.threadRoute of
                        Route.ViewThreadWithFriends index _ _ ->
                            if index == threadMessageIndex then
                                Ok ()

                            else
                                Err "The DM thread route points at the wrong message"

                        Route.NoThreadWithFriends _ _ ->
                            Err "Expected the DM route to be viewing a thread"

                _ ->
                    Err "Expected to be viewing a DM channel"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


{-| Writing a message counts as reading it, so the thread it went into holds nothing
unread for the person who wrote it.
-}
checkDmThreadIsRead : Id.Id Id.UserId -> Id.Id Id.ChannelMessageId -> FrontendModel -> Result String ()
checkDmThreadIsRead otherUserId threadMessageIndex model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    let
                        local : LocalState
                        local =
                            Local.model loggedIn.localState

                        newestMessageId : Maybe (Id.Id Id.ThreadMessageId)
                        newestMessageId =
                            SeqDict.get otherUserId local.dmChannels
                                |> Maybe.andThen (\dmChannel -> SeqDict.get threadMessageIndex dmChannel.threads)
                                |> Maybe.map DmChannel.latestFrontendThreadMessageId
                    in
                    if
                        SeqDict.get
                            ( Id.GuildOrDmId (Id.GuildOrDmId_Dm { otherUserId = otherUserId }), threadMessageIndex )
                            local.localUser.user.lastViewedThreadMessage
                            == newestMessageId
                    then
                        Ok ()

                    else
                        Err "Expected the newest message in the DM thread to have been read"

                Types.NotLoggedIn _ ->
                    Err "Expected the frontend to be logged in"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


checkDmRouteWithUser : Id.Id Id.UserId -> FrontendModel -> Result String ()
checkDmRouteWithUser otherUserId model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case ( loaded.loginStatus, loaded.route ) of
                ( Types.LoggedIn loggedIn, Route.DmRoute dmRoute ) ->
                    let
                        currentUserId : Id.Id Id.UserId
                        currentUserId =
                            (Local.model loggedIn.localState).localUser.session.userId
                    in
                    if DmChannelId.otherUserId currentUserId dmRoute.channelId == Just otherUserId then
                        Ok ()

                    else
                        Err "Opened a DM channel with the wrong user"

                ( Types.LoggedIn _, _ ) ->
                    Err "Expected to be viewing a DM channel"

                ( Types.NotLoggedIn _, _ ) ->
                    Err "Expected the frontend to be logged in"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


{-| A message someone else writes into the conversation you are looking at, with nothing
unread in it, shouldn't leave you with something unread. The conversation stays caught up
while you sit in it, and it is still caught up once you leave.
-}
staysReadWhileViewingTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
staysReadWhileViewingTest config =
    E2EHelper.startTest
        "Messages arriving in the conversation you are looking at stay read"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ -- The guild channel both of them are looking at
                  E2EHelper.writeMessage admin 100 "In the channel"
                , checkChannelIsCaughtUp guildChannelId user
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.hasExactText user [ "You have no unread messages!" ]

                -- A message arriving while the reader is elsewhere is still unread
                , E2EHelper.writeMessage admin 100 "While away"
                , E2EHelper.hasNotExactText user [ "You have no unread messages!" ]
                , E2EHelper.hasExactText user [ "While away" ]

                -- Opening the channel catches them up again, and a thread started from a
                -- message counts separately from the channel it hangs off
                , user.click 100 (Dom.id "guild_openGuild_1")
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "new" ])
                , E2EHelper.createThread admin (Id.fromInt 1)
                , E2EHelper.writeMessage admin 100 "Starting a thread"
                , user.click 100 (Dom.id "guild_viewThread_0_1")
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "new" ])
                , E2EHelper.writeMessage admin 100 "In the thread"
                , checkThreadIsCaughtUp guildChannelId (Id.fromInt 1) user
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.hasExactText user [ "You have no unread messages!" ]

                -- The same in a DM, where the reader knows the conversation by the person
                -- writing to them
                , E2EHelper.openDm admin 100 "2"
                , E2EHelper.writeMessage admin 100 "Hello in a DM!"
                , user.click 100 (Dom.id "guild_friendLabel_0")
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "new" ])
                , E2EHelper.writeMessage admin 100 "And another one"
                , checkChannelIsCaughtUp dmWithAdminId user
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.hasExactText user [ "You have no unread messages!" ]

                -- A reader who is behind stays where they are. Marking "While away" as
                -- unread puts them one message back, and a message arriving while they are
                -- still looking at the channel leaves that where it is instead of catching
                -- them up over the top of it.
                , user.click 100 (Dom.id "guild_openGuild_1")
                , user.click 100 (Dom.id "guild_openChannel_0")
                , markAsUnread user (Id.fromInt 2)
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "new" ])
                , user.checkModel 100 (checkLastViewedMessageIs guildChannelId (Id.fromInt 1))
                , admin.click 100 (Dom.id "guild_openGuild_1")
                , admin.click 100 (Dom.id "guild_openChannel_0")
                , E2EHelper.writeMessage admin 100 "After the mark"
                , E2EHelper.hasExactText user [ "After the mark" ]
                , user.checkModel 100 (checkLastViewedMessageIs guildChannelId (Id.fromInt 1))
                , E2EHelper.tallSnapshot user 100 { name = "Unread divider stays put while viewing" }

                -- Opening one of the channel's tabs isn't arriving in a conversation they
                -- weren't already in, so that leaves the mark where it is too
                , user.click 100 (Dom.id "guild_openGamesTab")
                , user.checkModel 100 (checkLastViewedMessageIs guildChannelId (Id.fromInt 1))

                -- Which is what the unread overview shows once they leave: everything from
                -- the message they marked onwards, and nothing from before it
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.hasExactText user [ "While away", "After the mark" ]
                , E2EHelper.hasNotExactText user [ "In the channel" ]
                , E2EHelper.tallSnapshot user 100 { name = "Unread overview after a message marked as unread" }
                ]
            )
        ]


{-| Landing in a conversation because the page was loaded on its url isn't the reader having
read what turned up while they were away. The unread divider is still there for them to look
at rather than the messages being marked as read on their behalf as the page loads.
-}
reloadingAConversationLeavesItUnreadTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
reloadingAConversationLeavesItUnreadTest config =
    E2EHelper.startTest
        "Loading the url of a conversation leaves what's unread in it unread"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.writeMessage admin 100 "In the channel"
                , checkChannelIsCaughtUp guildChannelId user

                -- The reader goes elsewhere and a message turns up without them
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.writeMessage admin 100 "While away"
                , E2EHelper.hasNotExactText user [ "You have no unread messages!" ]

                -- Loading the channel's url puts them back in it with that message still
                -- unread, so the divider above it is what they see
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode
                        (Route.GuildRoute
                            (Id.fromInt 1)
                            (Route.ChannelRoute
                                (Id.fromInt 0)
                                (Route.NoThreadWithFriends Nothing Route.HideChannelSettings)
                                Nothing
                            )
                            ChannelsHiddenOnMobile
                        )
                    )
                    E2EHelper.desktopWindow
                    (\reloaded ->
                        [ T.andThen
                            10
                            (\data ->
                                [ reloaded.portEvent
                                    10
                                    "load_startup_data_from_js"
                                    (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                                ]
                            )
                        , reloaded.checkView
                            500
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "While away" ])
                        , reloaded.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.exactText "new" ])
                        , reloaded.checkModel 100 (checkLastViewedMessageIs guildChannelId (Id.fromInt 1))
                        ]
                    )
                ]
            )
        ]


{-| Swiping the conversation view off screen on mobile has to tell the backend the reader
isn't looking at it any more, otherwise messages written while they sit on the channel list
are marked as read on their behalf.
-}
swipedAwayConversationStopsBeingViewedTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
swipedAwayConversationStopsBeingViewedTest config =
    E2EHelper.startTest
        "Swiping the conversation view closed on mobile stops it counting as viewed"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.iphone14Window
            (\admin user ->
                [ -- A guild channel is what the reader lands in, so that's what the backend
                  -- has them looking at
                  T.checkState 100 checkBackendIsViewingTheChannel
                , E2EHelper.writeMessageMobile admin "While looking at the channel"
                , user.checkModel 100 (checkLastViewedMessageIs guildChannelId (Id.fromInt 1))

                -- Swiping it away leaves them on the guild's channel list, which the
                -- backend has to hear about
                , user.click 100 (Dom.id "guild_headerBackButton")
                , T.checkState 500 checkBackendIsViewingNothing
                , E2EHelper.writeMessageMobile admin "While the channel is swiped away"
                , user.checkModel 100 (checkLastViewedMessageIs guildChannelId (Id.fromInt 1))

                -- The same goes for a DM, where swiping the conversation away leaves them
                -- on the friends list instead
                , E2EHelper.openDm admin 100 "2"
                , E2EHelper.writeMessageMobile admin "Starting a DM"
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , user.click 100 (Dom.id "guild_friendLabel_0")
                , T.checkState 100 checkBackendIsViewingTheDm
                , E2EHelper.writeMessageMobile admin "While looking at the DM"
                , user.checkModel 100 (checkLastViewedMessageIs dmWithAdminId (Id.fromInt 1))
                , user.click 100 (Dom.id "guild_headerBackButton")
                , T.checkState 500 checkBackendIsViewingNothing
                , E2EHelper.writeMessageMobile admin "While the DM is swiped away"
                , user.checkModel 100 (checkLastViewedMessageIs dmWithAdminId (Id.fromInt 1))
                , E2EHelper.tallSnapshot user 100 { name = "DM left unread while swiped away" }
                ]
            )
        ]


checkBackendIsViewingTheChannel : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkBackendIsViewingTheChannel data =
    case E2EHelper.backendViewing E2EHelper.sessionId1 data of
        Ok (UserSession.Viewing_Channel _) ->
            Ok ()

        Ok _ ->
            Err "Expected the backend to have the reader viewing the guild channel"

        Err error ->
            Err error


checkBackendIsViewingTheDm : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkBackendIsViewingTheDm data =
    case E2EHelper.backendViewing E2EHelper.sessionId1 data of
        Ok (UserSession.Viewing_Dm _) ->
            Ok ()

        Ok _ ->
            Err "Expected the backend to have the reader viewing the DM"

        Err error ->
            Err error


checkBackendIsViewingNothing : T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkBackendIsViewingNothing data =
    case E2EHelper.backendViewing E2EHelper.sessionId1 data of
        Ok UserSession.Viewing_None ->
            Ok ()

        Ok _ ->
            Err "Expected the backend to hear that the swiped away conversation is no longer being viewed"

        Err error ->
            Err error


{-| The reader is behind by however far the given message sits from the newest one, which
is what the unread divider and the notification counts are drawn from.
-}
checkLastViewedMessageIs : Id.AnyGuildOrDmId -> Id.Id Id.ChannelMessageId -> FrontendModel -> Result String ()
checkLastViewedMessageIs guildOrDmId messageId model =
    withLocalState
        model
        (\local ->
            case SeqDict.get guildOrDmId local.localUser.user.lastViewedMessage of
                Just lastViewed ->
                    if lastViewed == messageId then
                        Ok ()

                    else
                        Err
                            ("Expected the last viewed message to be "
                                ++ Id.toString messageId
                                ++ " but it is "
                                ++ Id.toString lastViewed
                            )

                Nothing ->
                    Err "Expected the channel to have been viewed"
        )


guildChannelId : Id.AnyGuildOrDmId
guildChannelId =
    Id.GuildOrDmId (Id.GuildOrDmId_Guild { guildId = Id.fromInt 1, channelId = Id.fromInt 0 })


dmWithAdminId : Id.AnyGuildOrDmId
dmWithAdminId =
    Id.GuildOrDmId (Id.GuildOrDmId_Dm { otherUserId = Id.fromInt 0 })


{-| The reader has seen every message in the channel, which is what the notification counts
and the unread overview are worked out from.
-}
checkChannelIsCaughtUp :
    Id.AnyGuildOrDmId
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkChannelIsCaughtUp guildOrDmId user =
    T.group
        [ user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "new" ])
        , user.checkModel
            0
            (\model ->
                withLocalState
                    model
                    (\local ->
                        case ( SeqDict.get guildOrDmId local.localUser.user.lastViewedMessage, latestChannelMessageId guildOrDmId local ) of
                            ( lastViewed, Just latest ) ->
                                if lastViewed == Just latest then
                                    Ok ()

                                else
                                    Err
                                        ("Expected the channel to be caught up at "
                                            ++ Id.toString latest
                                            ++ " but the last viewed message is "
                                            ++ (case lastViewed of
                                                    Just messageId ->
                                                        Id.toString messageId

                                                    Nothing ->
                                                        "nothing"
                                               )
                                        )

                            ( _, Nothing ) ->
                                Err "Expected the channel to exist"
                    )
            )
        ]


checkThreadIsCaughtUp :
    Id.AnyGuildOrDmId
    -> Id.Id Id.ChannelMessageId
    -> T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
checkThreadIsCaughtUp guildOrDmId threadId user =
    T.group
        [ user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "new" ])
        , user.checkModel
            0
            (\model ->
                withLocalState
                    model
                    (\local ->
                        case ( SeqDict.get ( guildOrDmId, threadId ) local.localUser.user.lastViewedThreadMessage, latestThreadMessageId guildOrDmId threadId local ) of
                            ( lastViewed, Just latest ) ->
                                if lastViewed == Just latest then
                                    Ok ()

                                else
                                    Err "Expected the thread to be caught up with its newest message"

                            ( _, Nothing ) ->
                                Err "Expected the thread to exist"
                    )
            )
        ]


latestChannelMessageId : Id.AnyGuildOrDmId -> LocalState -> Maybe (Id.Id Id.ChannelMessageId)
latestChannelMessageId guildOrDmId local =
    case guildOrDmId of
        Id.GuildOrDmId (Id.GuildOrDmId_Guild id) ->
            LocalState.getGuildAndChannel id local
                |> Maybe.map (\( _, channel ) -> DmChannel.latestFrontendMessageId channel)

        Id.GuildOrDmId (Id.GuildOrDmId_Dm id) ->
            SeqDict.get id.otherUserId local.dmChannels
                |> Maybe.map DmChannel.latestFrontendMessageId

        Id.DiscordGuildOrDmId _ ->
            Nothing


latestThreadMessageId : Id.AnyGuildOrDmId -> Id.Id Id.ChannelMessageId -> LocalState -> Maybe (Id.Id Id.ThreadMessageId)
latestThreadMessageId guildOrDmId threadId local =
    case guildOrDmId of
        Id.GuildOrDmId (Id.GuildOrDmId_Guild id) ->
            LocalState.getGuildAndChannel id local
                |> Maybe.andThen (\( _, channel ) -> SeqDict.get threadId channel.threads)
                |> Maybe.map DmChannel.latestFrontendThreadMessageId

        Id.GuildOrDmId (Id.GuildOrDmId_Dm id) ->
            SeqDict.get id.otherUserId local.dmChannels
                |> Maybe.andThen (\dmChannel -> SeqDict.get threadId dmChannel.threads)
                |> Maybe.map DmChannel.latestFrontendThreadMessageId

        Id.DiscordGuildOrDmId _ ->
            Nothing


withLocalState : FrontendModel -> (LocalState -> Result String ()) -> Result String ()
withLocalState model func =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    func (Local.model loggedIn.localState)

                Types.NotLoggedIn _ ->
                    Err "Expected the frontend to be logged in"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


markMessageAsUnreadTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
markMessageAsUnreadTest config =
    E2EHelper.startTest
        "Mark a message as unread"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    -- "Two" and "Three" are unread, the message announcing that the user
                    -- joined and "One" are not
                    twoUnread : Test.Html.Selector.Selector
                    twoUnread =
                        Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "2")
                in
                [ E2EHelper.writeMessage admin 100 "One"
                , E2EHelper.writeMessage admin 100 "Two"
                , E2EHelper.writeMessage admin 100 "Three"

                -- Leaving the channel marks everything in it as read
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.hasExactText user [ "You have no unread messages!" ]
                , user.checkView 100 (Test.Html.Query.hasNot [ twoUnread ])

                -- Marking the second of the three messages as unread leaves it and the
                -- message after it unread
                , user.click 100 (Dom.id "guild_openGuild_1")
                , markAsUnread user (Id.fromInt 2)
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , user.checkView 100 (Test.Html.Query.has [ twoUnread ])
                , E2EHelper.hasExactText user [ "Two", "Three" ]
                , E2EHelper.hasNotExactText user [ "One" ]

                -- Hovering a message in the overview restarts the animations inside it and
                -- offers to react to it. Editing, replying and the full menu belong to the
                -- channel the message came from, so the menu here leaves them out
                , user.mouseEnter 100 (Dom.id "guild_message_2") ( 10, 10 ) []
                , user.checkModel 100 (checkMessageIsHovered (Id.fromInt 2))
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "miniView_showReactionEmojiSelector"
                        , Test.Html.Selector.id "miniView_emojiReact_0"
                        ]
                    )
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "miniView_showFullMenu" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "miniView_reply" ])
                , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "miniView_editMessage" ])
                , E2EHelper.tallSnapshot user 100 { name = "Reaction menu on an unread overview message" }

                -- The shortcut reacts with the emoji drawn on it, without leaving the overview
                , user.click 100 (Dom.id "miniView_emojiReact_0")
                , user.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_removeReactionEmoji_0" ])

                -- And the button beside the shortcuts opens the emoji selector over the
                -- overview, for a reaction that isn't one of them
                , user.click 100 (Dom.id "miniView_showReactionEmojiSelector")
                , user.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id (Dom.idToString Emoji.searchInputId) ]
                    )
                , user.click 100 (Dom.id "miniView_showReactionEmojiSelector")

                -- Reading the channel for real puts the unread count away again
                , user.click 100 (Dom.id "guild_openGuild_1")
                , user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.hasExactText user [ "You have no unread messages!" ]
                , user.checkView 100 (Test.Html.Query.hasNot [ twoUnread ])
                ]
            )
        ]


markAsUnread :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> Id.Id Id.ChannelMessageId
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
markAsUnread user messageId =
    T.group
        [ user.mouseEnter 100 (Dom.id ("guild_message_" ++ Id.toString messageId)) ( 10, 10 ) []
        , user.custom
            100
            (Dom.id "miniView_showFullMenu")
            "click"
            (Json.Encode.object
                [ ( "clientX", Json.Encode.int 500 )
                , ( "clientY", Json.Encode.int 300 )
                ]
            )
        , user.click 100 (Dom.id "messageMenu_markAsUnread")
        ]


checkMessageIsHovered : Id.Id Id.ChannelMessageId -> FrontendModel -> Result String ()
checkMessageIsHovered messageId model =
    case Audio.userModel model of
        Types.Loaded loaded ->
            case loaded.loginStatus of
                Types.LoggedIn loggedIn ->
                    if
                        loggedIn.messageHover
                            == Types.MessageHover
                                (Id.GuildOrDmId (Id.GuildOrDmId_Guild { guildId = Id.fromInt 1, channelId = Id.fromInt 0 }))
                                (Id.NoThreadWithMessage messageId)
                    then
                        Ok ()

                    else
                        Err "Expected the message in the unread overview to be hovered"

                Types.NotLoggedIn _ ->
                    Err "Expected the frontend to be logged in"

        Types.Loading _ ->
            Err "Expected the frontend to have finished loading"


inactiveThreadsAreHiddenTest : T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2 -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
inactiveThreadsAreHiddenTest config =
    T.start
        "Inactive threads are hidden"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , E2EHelper.inviteUser
                    admin
                    (\user ->
                        [ E2EHelper.writeMessage user 100 "Hello!"
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , E2EHelper.writeMessage admin 100 "Hello from admin!"
                        , E2EHelper.createThread admin (Id.fromInt 0)
                        , E2EHelper.writeMessage admin 100 "Hello from admin in thread!"
                        , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        , admin.click 100 (Dom.id "guild_openChannel_0")
                        , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                        ]
                    )
                ]
            )
        , T.connectFrontend
            (Duration.days 7.1 |> Duration.inMilliseconds)
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ T.andThen
                    10
                    (\data -> [ admin.portEvent 10 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                , admin.click 100 (Dom.id "guild_openGuild_0")
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.navigateBack 100
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , E2EHelper.writeMessage admin 100 "Hello again from thread!"
                , admin.navigateBack 100
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewThread_0_0" ])
                ]
            )
        ]


{-| DM threads carry their own route, are listed underneath the DM in the friends
column and notify with the red count that every unread DM message gets.
-}
dmThreadsTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
dmThreadsTest config =
    E2EHelper.startTest
        "DM threads"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    -- The DM holds one unread message and the thread inside it two, so the
                    -- two notification counts can be told apart. The DM's own icon counts
                    -- both, which makes three.
                    threadNotification : Test.Html.Selector.Selector
                    threadNotification =
                        Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "2")

                    dmNotification : Test.Html.Selector.Selector
                    dmNotification =
                        Test.Html.Selector.attribute (Html.Attributes.attribute "aria-label" "3")
                in
                [ -- The user waits on the friends page while the admin writes to them
                  user.click 100 (Dom.id "guildIcon_showFriends")
                , E2EHelper.openDm admin 100 "2"
                , E2EHelper.writeMessage admin 100 "Hello in a DM!"
                , E2EHelper.createThread admin (Id.fromInt 0)
                , E2EHelper.writeMessage admin 100 "First message in the DM thread"
                , E2EHelper.writeMessage admin 100 "Second message in the DM thread"

                -- Opening a thread from a DM message puts the thread in the route
                , admin.checkModel 100 (checkDmThreadRoute (Id.fromInt 0))

                -- The admin wrote those two thread messages, so neither is unread for them
                , admin.checkModel 100 (checkDmThreadIsRead (Id.fromInt 2) (Id.fromInt 0))

                -- The thread is listed underneath the DM for both of them. The admin sees
                -- it under the user (id 2) and the user sees it under the admin (id 0).
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])
                , user.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_0_0" ])

                -- Unread thread messages notify the user, who has read none of them
                , user.checkView 100 (Test.Html.Query.has [ threadNotification, dmNotification ])

                -- The unread overview names the DM after the person on the other end of
                -- it, and the thread after the message it hangs off
                , user.checkView
                    100
                    (\html ->
                        Test.Html.Query.find
                            [ Test.Html.Selector.id "guild_unreadOverviewOpenChannel_dm_0" ]
                            html
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Chat with"
                                , Test.Html.Selector.exactText E2EHelper.adminName
                                ]
                    )
                , user.checkView
                    100
                    (\html ->
                        Test.Html.Query.find
                            [ Test.Html.Selector.id "guild_unreadOverviewOpenChannel_dm_0_thread_0" ]
                            html
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.exactText "Chat with"
                                , Test.Html.Selector.exactText E2EHelper.adminName
                                , Test.Html.Selector.exactText "Hello in a DM!"
                                ]
                    )
                , user.snapshotView 100 { name = "User perspective" }
                , admin.snapshotView 100 { name = "Admin perspective" }

                -- Writing in the thread reaches the other user, and the thread's messages
                -- stay out of the DM itself
                , user.click 100 (Dom.id "guild_viewDmThread_0_0")
                , E2EHelper.hasExactText user [ "First message in the DM thread", "Second message in the DM thread" ]
                , E2EHelper.writeMessage user 100 "Reply from the user"
                , user.checkModel 100 (checkDmThreadIsRead (Id.fromInt 0) (Id.fromInt 0))
                , E2EHelper.hasExactText admin [ "Reply from the user" ]
                , user.click 100 (Dom.id "guild_friendLabel_0")
                , E2EHelper.hasExactText user [ "Hello in a DM!" ]
                , E2EHelper.hasNotExactText user [ "First message in the DM thread", "Reply from the user" ]

                -- Reading the thread took its notification away. The DM's own message is
                -- still unread until the DM itself is opened, so its icon drops from three
                -- to one instead of disappearing.
                , user.checkView 100 (Test.Html.Query.hasNot [ threadNotification, dmNotification ])

                -- The thread is stored on the backend, so loading its url from scratch
                -- shows the messages and lists the thread under the DM again
                , T.connectFrontend
                    100
                    E2EHelper.sessionId1
                    (Route.encode
                        (Route.DmRoute
                            { channelId = DmChannelId.fromUserIds (Id.fromInt 0) (Id.fromInt 2)
                            , threadRoute = Route.ViewThreadWithFriends (Id.fromInt 0) Nothing Route.HideChannelSettings
                            , tab = Nothing
                            , channelsVisible = ChannelsHiddenOnMobile
                            }
                        )
                    )
                    E2EHelper.desktopWindow
                    (\userReload ->
                        [ T.andThen
                            10
                            (\data ->
                                [ userReload.portEvent
                                    10
                                    "load_startup_data_from_js"
                                    (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                                ]
                            )
                        , E2EHelper.hasExactText
                            userReload
                            [ "First message in the DM thread", "Reply from the user" ]
                        , userReload.checkView
                            2000
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_0_0" ])
                        ]
                    )
                ]
            )
        ]


{-| Just like a guild channel's threads, a DM thread drops out of the friends
column once it's been quiet for a week, and comes back as soon as it's opened
again.
-}
inactiveDmThreadsAreHiddenTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
inactiveDmThreadsAreHiddenTest config =
    E2EHelper.startTest
        "Inactive DM threads are hidden"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.openDm admin 100 "2"
                , E2EHelper.writeMessage admin 100 "Hello in a DM!"
                , E2EHelper.createThread admin (Id.fromInt 0)
                , E2EHelper.writeMessage admin 100 "Hello in the thread!"
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])
                ]
            )
        , T.connectFrontend
            (Duration.days 7.1 |> Duration.inMilliseconds)
            E2EHelper.sessionId0
            "/"
            E2EHelper.desktopWindow
            (\admin ->
                [ T.andThen
                    10
                    (\data ->
                        [ admin.portEvent
                            10
                            "load_startup_data_from_js"
                            (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop)
                        ]
                    )

                -- A week without a message and nothing unread in it, so the thread is gone
                -- from the column
                , admin.checkView
                    2000
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])

                -- Opening it from the DM message it hangs off puts it back
                , admin.click 100 (Dom.id "guild_friendLabel_2")
                , admin.click 100 (Dom.id "guild_threadStarterIndicator_0")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.id "guild_viewDmThread_2_0" ])
                , E2EHelper.hasExactText admin [ "Hello in the thread!" ]
                , admin.snapshotView 100 { name = "Inactive threads are hidden" }
                ]
            )
        ]


{-| Noon on the day `E2EHelper.startTime` falls on. The suggestions a timestamp dropdown makes
are relative to the time the test is running at, so starting at midday leaves room either side
of it for them to land on the same day and read as a time rather than a date.
-}
middayStartTime : Time.Posix
middayStartTime =
    Duration.addTo E2EHelper.startTime (Duration.hours 12)


{-| The minutes of every timestamp in the most recent message the backend has stored.
-}
lastMessageTimestamps : E2EHelper.BackendModel2 -> List Int
lastMessageTimestamps backend =
    case E2EHelper.lastGuildChannelMessage backend of
        Just ( _, _, Message.UserTextMessage data ) ->
            List.Nonempty.toList data.content
                |> List.filterMap
                    (\part ->
                        case part of
                            RichText.Timestamp time ->
                                TimeInMinutes.toSeconds time // 60 |> Just

                            _ ->
                                Nothing
                    )

        _ ->
            []


expectLastMessageTimestamps : List Int -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
expectLastMessageTimestamps expected data =
    if lastMessageTimestamps data.backend == expected then
        Ok ()

    else
        Err
            ("Expected the stored message to hold timestamps at "
                ++ String.join "," (List.map String.fromInt expected)
                ++ " minutes but it held "
                ++ String.join "," (List.map String.fromInt (lastMessageTimestamps data.backend))
            )


{-| Noon on the 15th of July 2026, read in `E2EHelper.testTimezone`, in minutes since the
epoch. The clocks are forward an hour by then, so it's 11:00 UTC.
-}
summerNoon : Int
summerNoon =
    29735220


{-| Noon on the 15th of December 2026, read in `E2EHelper.testTimezone`. The clocks have gone
back by then, so it's 12:00 UTC and an hour later in the day than `summerNoon` would suggest.
-}
winterNoon : Int
winterNoon =
    29955600


{-| Writing a time of day offers the times a clock shows it at, and the one that's picked is
still a timestamp by the time the backend has it.
-}
timeOfDaySuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
timeOfDaySuggestionTest config =
    E2EHelper.startTest
        "Writing a time of day suggests timestamps"
        middayStartTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at 18:00"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 13, end = 13 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Add a timestamp" ])

                -- Suggestions that land on another day read as a date, which is the same text
                -- that picking them writes into the message.
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "January 2, 1970 at 06:00" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "January 2, 1970 at 18:00" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at July 15, 2026 at 12:00"

                -- Enter picks a suggestion while the dropdown is open, so it has to be shut
                -- before the message can be sent. Writing out a whole timestamp shuts it,
                -- since the time of day on the end of one is already part of a timestamp.
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 30, end = 30 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ summerNoon ])
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at December 15, 2026 at 12:00"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 34, end = 34 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ winterNoon ])
                ]
            )
        ]


{-| Writing a time offset suggests times either side of now, and the timestamp that ends up in
the message is still there after the message has been round tripped through an edit.
-}
timeOffsetSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
timeOffsetSuggestionTest config =
    E2EHelper.startTest
        "Writing a time offset suggests a timestamp that survives being sent and edited"
        middayStartTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                let
                    withTimestamp : String
                    withTimestamp =
                        "Remind me in January 1, 1970 at 17:00"
                in
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId
                , admin.input 100 Pages.Guild.channelTextInputId "Remind me in 5 hours"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 20, end = 20 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Add a timestamp" ])

                -- Picking a suggestion closes the dropdown. What it writes into the message is
                -- put there by js, which these tests don't run, so the text it would have left
                -- behind is typed in its place.
                , admin.click 100 (Pages.Guild.dropdownButtonId 0)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])
                , admin.input 100 Pages.Guild.channelTextInputId withTimestamp
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ 17 * 60 ])

                -- The message shows the moment rather than the words that were typed.
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "17:00" ])

                -- Editing turns the message back into text, which is where a timestamp that
                -- can't be read back would be lost.
                , E2EHelper.focusEvent admin 100 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.keyDown 100 Pages.Guild.channelTextInputId "ArrowUp" []
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "editMessageTextInput"
                        , Test.Html.Selector.attribute (Html.Attributes.value withTimestamp)
                        ]
                    )
                , admin.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
                , T.checkState 100 (expectLastMessageTimestamps [ 17 * 60 ])
                ]
            )
        ]


{-| The dropdown stays out of the way of text that isn't asking for a timestamp, including the
time of day at the end of a timestamp that's already there.
-}
noTimestampSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
noTimestampSuggestionTest config =
    E2EHelper.startTest
        "Text that isn't asking for a timestamp doesn't get one suggested"
        middayStartTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId
                , admin.input 100 Pages.Guild.channelTextInputId "see you later"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 13, end = 13 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])

                -- A unit needs a number in front of it to be an offset.
                , admin.input 100 Pages.Guild.channelTextInputId "later that day"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 14, end = 14 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])

                -- The 18:00 on the end of a timestamp is already part of one, so offering to
                -- turn it into another would nest a timestamp inside the one that's there.
                , admin.input 100 Pages.Guild.channelTextInputId "Meet at January 1, 1970 at 18:00"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 32, end = 32 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])

                -- Away from the end of the words it reads, there's nothing to replace.
                , admin.input 100 Pages.Guild.channelTextInputId "Remind me in 5 hours and also buy milk"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 38, end = 38 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a timestamp" ])
                ]
            )
        ]


{-| How many people the most recent message the backend has stored mentions.
-}
lastMessageMentionCount : E2EHelper.BackendModel2 -> Int
lastMessageMentionCount backend =
    case E2EHelper.lastGuildChannelMessage backend of
        Just ( _, _, Message.UserTextMessage data ) ->
            List.Nonempty.toList data.content
                |> List.filter
                    (\part ->
                        case part of
                            RichText.UserMention _ ->
                                True

                            _ ->
                                False
                    )
                |> List.length

        _ ->
            0


{-| Writing an @ suggests the people who can be mentioned, and the one that's picked is a
mention rather than their name in text by the time the backend has it.
-}
mentionSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
mentionSuggestionTest config =
    E2EHelper.startTest
        "Writing an @ suggests people to mention"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId

                -- Only the people in the guild whose name starts with what's been written so
                -- far, so the admin's own name isn't among them.
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @S"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 6, end = 6 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Mention a user" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "Stevie Steve" ])

                -- A name nobody in the guild has leaves nothing to suggest.
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @Zz"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 7, end = 7 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Mention a user" ])

                -- Picking a suggestion closes the dropdown. The name it writes into the message
                -- is put there by js, which these tests don't run, so the text it would have
                -- left behind is typed in its place.
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @S"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 6, end = 6 }
                , admin.click 100 (Pages.Guild.dropdownButtonId 0)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Mention a user" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Hey @Stevie Steve"
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , T.checkState
                    100
                    (\data ->
                        if lastMessageMentionCount data.backend == 1 then
                            Ok ()

                        else
                            Err
                                ("Expected the stored message to mention one person but it mentioned "
                                    ++ String.fromInt (lastMessageMentionCount data.backend)
                                )
                    )
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText "@Stevie Steve" ])
                ]
            )
        ]


{-| Writing a colon and enough of a name to narrow it down suggests emoji to add.
-}
emojiSuggestionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
emojiSuggestionTest config =
    E2EHelper.startTest
        "Writing a colon suggests emoji"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId

                -- Two characters match too much of the emoji list to be worth showing.
                , admin.input 100 Pages.Guild.channelTextInputId "Party :ta"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 9, end = 9 }
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a sticker or emoji" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Party :tada"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 11, end = 11 }
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Add a sticker or emoji" ])
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.exactText ":tada:" ])

                -- Picking a suggestion closes the dropdown. As with a mention, what it writes
                -- into the message is put there by js, so the emoji it would have left behind
                -- is typed in its place.
                , admin.click 100 (Pages.Guild.dropdownButtonId 0)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text "Add a sticker or emoji" ])
                , admin.input 100 Pages.Guild.channelTextInputId "Party 🎉"
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "🎉" ])
                ]
            )
        ]


{-| Checks what's been written into the channel message input so far.
-}
checkDraft : Maybe String -> FrontendModel -> Result String ()
checkDraft expected model =
    let
        draft : Maybe String
        draft =
            case Audio.userModel model of
                Types.Loaded loaded ->
                    case loaded.loginStatus of
                        Types.LoggedIn loggedIn ->
                            SeqDict.values loggedIn.drafts
                                |> List.head
                                |> Maybe.map String.Nonempty.toString

                        Types.NotLoggedIn _ ->
                            Nothing

                Types.Loading _ ->
                    Nothing
    in
    if draft == expected then
        Ok ()

    else
        Err
            ("Expected the message input to contain "
                ++ Maybe.withDefault "nothing" expected
                ++ " but it contained "
                ++ Maybe.withDefault "nothing" draft
            )


{-| While the cursor is inside a \`\`\` code block, enter writes a line break instead of sending the
message and tab writes two spaces instead of moving the focus.
-}
codeBlockInputTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
codeBlockInputTest config =
    E2EHelper.startTest
        "Enter and tab behave differently inside a code block"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin _ ->
                [ E2EHelper.focusEvent admin 1000 (Just Pages.Guild.channelTextInputId) (Just { start = 0, end = 0 })
                , admin.click 100 Pages.Guild.channelTextInputId

                -- The code block hasn't been closed yet so enter is left to the textarea to
                -- handle (which writes a line break) rather than sending the message.
                , admin.input 100 Pages.Guild.channelTextInputId "```"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 3, end = 3 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , admin.checkModel 100 (checkDraft (Just "```"))

                -- Tab writes two spaces. Normally js is what puts them in the text input but
                -- these tests don't run js, so only the model is checked here.
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Tab" []
                , admin.checkModel 100 (checkDraft (Just "```  "))

                -- Once the code block is closed, the cursor is outside of it again and enter
                -- sends the message.
                , admin.input 100 Pages.Guild.channelTextInputId "```\nlet x = 1\n```"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 17, end = 17 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Enter" []
                , admin.checkModel 100 (checkDraft Nothing)
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "let x = 1" ])

                -- Tab is only special inside a code block. Everywhere else it's left alone so
                -- that it still moves the focus.
                , admin.input 100 Pages.Guild.channelTextInputId "no code block"
                , E2EHelper.selectionEvent admin 100 Pages.Guild.channelTextInputId { start = 13, end = 13 }
                , admin.keyDown 100 Pages.Guild.channelTextInputId "Tab" []
                , admin.checkModel 100 (checkDraft (Just "no code block"))
                ]
            )
        ]


{-| A call or a game leaves a card behind in the conversation it was started from. It is
the starter's own doing, the same as a message they wrote, so it doesn't leave them with
something unread or with the card sitting under an unread divider.
-}
startingACallOrGameStaysReadTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
startingACallOrGameStaysReadTest config =
    E2EHelper.startTest
        "Starting a call or a game doesn't leave the starter with something unread"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ -- The admin is caught up in the channel both of them are looking at
                  E2EHelper.writeMessage user 100 "In the channel"
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "new" ])

                -- Starting a call from it leaves them caught up on the card it wrote
                , admin.click 100 (Dom.id "guild_voiceChat")
                , E2EVoiceChat.startCall admin
                , admin.navigateBack 100
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "started a call" ])
                , admin.checkModel 100 (checkChannelIsCaughtUpModel guildChannelId)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "new" ])

                -- And so does starting a game
                , admin.click 100 (Dom.id "guild_openGamesTab")
                , admin.click 100 (Dom.id "game_select_Go (Baduk)")
                , admin.click 100 (Dom.id "go_start")
                , admin.navigateBack 100
                , admin.checkModel 100 (checkChannelIsCaughtUpModel guildChannelId)
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "new" ])
                , E2EHelper.tallSnapshot admin 100 { name = "Started a call and a game without either turning up unread" }
                ]
            )
        ]


{-| The reader has seen every message in the channel, which is what the notification counts
and the unread overview are worked out from.
-}
checkChannelIsCaughtUpModel : Id.AnyGuildOrDmId -> FrontendModel -> Result String ()
checkChannelIsCaughtUpModel guildOrDmId model =
    withLocalState
        model
        (\local ->
            case ( SeqDict.get guildOrDmId local.localUser.user.lastViewedMessage, latestChannelMessageId guildOrDmId local ) of
                ( Just lastViewed, Just latest ) ->
                    if lastViewed == latest then
                        Ok ()

                    else
                        Err
                            ("Expected the channel to be caught up at "
                                ++ Id.toString latest
                                ++ " but the last viewed message is "
                                ++ Id.toString lastViewed
                            )

                _ ->
                    Err "Expected the channel to exist and to have been viewed"
        )


leaveGuildTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
leaveGuildTest config =
    E2EHelper.startTest
        "A member leaves a guild from the guild settings page"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                let
                    guildId : Id.Id Id.GuildId
                    guildId =
                        Id.fromInt 1
                in
                [ -- The owner can delete the guild but has no way to leave it
                  admin.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , E2EHelper.hasExactText admin [ "Delete guild" ]
                , E2EHelper.hasNotExactText admin [ "Leave guild" ]

                -- A member gets the leave button instead
                , user.click 100 (Dom.id "guild_inviteLinkCreatorRoute")
                , E2EHelper.hasExactText user [ "Leave guild" ]
                , E2EHelper.hasNotExactText user [ "Delete guild" ]
                , user.snapshotView 100 { name = "Guild settings for a member who isn't the owner" }

                -- The first press only asks for confirmation
                , user.click 100 (Dom.id "guild_leaveGuild")
                , E2EHelper.hasExactText user [ "Yes, leave guild" ]
                , T.checkBackend 100 (checkGuildMemberCount guildId 1)

                -- The second press leaves the guild
                , user.click 100 (Dom.id "guild_leaveGuild")
                , T.checkBackend 100 (checkGuildMemberCount guildId 0)
                , E2EHelper.hasNotExactText user [ "My new guild!" ]
                , user.checkModel
                    100
                    (\model ->
                        withLocalState
                            model
                            (\local ->
                                if SeqDict.member guildId local.guilds then
                                    Err "The guild should be gone from the frontend of the user who left"

                                else
                                    Ok ()
                            )
                    )

                -- The owner sees the member disappear without losing the guild
                , admin.checkModel
                    100
                    (\model ->
                        withLocalState
                            model
                            (\local ->
                                case SeqDict.get guildId local.guilds of
                                    Just guild ->
                                        if SeqDict.isEmpty (MembersAndOwner.members guild.membersAndOwner) then
                                            Ok ()

                                        else
                                            Err "The owner should no longer see the member who left"

                                    Nothing ->
                                        Err "The owner should still be in the guild"
                            )
                    )
                ]
            )
        ]


checkGuildMemberCount : Id.Id Id.GuildId -> Int -> E2EHelper.BackendModel2 -> Result String ()
checkGuildMemberCount guildId expected backend =
    case SeqDict.get guildId (E2EHelper.unwrapBackend backend).guilds of
        Just guild ->
            let
                count : Int
                count =
                    SeqDict.size (MembersAndOwner.members guild.membersAndOwner)
            in
            if count == expected then
                Ok ()

            else
                Err
                    ("Expected the guild to have "
                        ++ String.fromInt expected
                        ++ " members besides the owner but it has "
                        ++ String.fromInt count
                    )

        Nothing ->
            Err "The guild should still exist after a member leaves"


{-| The colour picker in the user options. The preview message is drawn on with the colour
that's selected, and nothing is saved until the submit button that turns up alongside it is
pressed.
-}
colorPickerTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
colorPickerTest config =
    E2EHelper.startTest
        "Pick a user colour"
        E2EHelper.startTime
        config
        [ T.connectFrontend
            100
            E2EHelper.sessionId0
            "/"
            E2EHelper.tallDesktopWindow
            (\admin ->
                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail admin
                , admin.click 1000 (Dom.id "guild_showUserOptions")

                -- The grid is a lot of squares, so it stays put away until asked for, with
                -- the colour they already have shown beside the button.
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "userOptions_selectColor"
                        , Test.Html.Selector.id "userOptions_currentColor"
                        ]
                    )
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "userColor_lightness" ])
                , admin.click 100 (Dom.id "userOptions_selectColor")

                -- Out come the picker and an example message scrawled on in whatever is
                -- selected.
                , admin.checkView
                    100
                    (Test.Html.Query.has
                        [ Test.Html.Selector.id "userColor_lightness"
                        , Test.Html.Selector.text "Hello"
                        ]
                    )
                , admin.checkView 100 (hasStrokeColored UserColor.default)

                -- Nothing to submit until the colour actually changes.
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "userOptions_submitColor" ])

                -- Turning the brightness right down leaves the chosen square too dark to be
                -- used, so the preview holds onto the last colour that could be and there's
                -- still nothing to submit.
                , admin.input 100 (Dom.id "userColor_lightness") "3"
                , admin.checkView 100 (hasStrokeColored UserColor.default)
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "userOptions_submitColor" ])

                -- Back to a brightness that works and the colour moves again.
                , admin.input 100 (Dom.id "userColor_lightness") "10"
                , admin.checkView
                    100
                    (Test.Html.Query.has [ Test.Html.Selector.id "userOptions_submitColor" ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ hasStrokeSelector UserColor.default ])

                -- Resetting puts the grid away without having saved anything.
                , admin.click 100 (Dom.id "userOptions_resetColor")
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "userColor_lightness" ])
                , T.checkState 100 (checkSavedColorIs UserColor.default)

                -- Submitting saves it and puts the grid away too.
                , admin.click 100 (Dom.id "userOptions_selectColor")
                , admin.input 100 (Dom.id "userColor_lightness") "10"
                , admin.click 100 (Dom.id "userOptions_submitColor")
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.id "userColor_lightness" ])
                , T.checkState 100 (checkSavedColorIsNot UserColor.default)
                ]
            )
        ]


hasStrokeSelector : UserColor.UserColor -> Test.Html.Selector.Selector
hasStrokeSelector color =
    Test.Html.Selector.attribute
        (Html.Attributes.attribute "stroke" (UserColor.toStyle color))


hasStrokeColored : UserColor.UserColor -> Test.Html.Query.Single msg -> Expect.Expectation
hasStrokeColored color view =
    Test.Html.Query.findAll [ hasStrokeSelector color ] view
        |> Test.Html.Query.count (Expect.greaterThan 0)


checkSavedColorIs : UserColor.UserColor -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkSavedColorIs expected state =
    if savedColor state == Just expected then
        Ok ()

    else
        Err "The colour the backend has saved isn't the one it should be"


checkSavedColorIsNot : UserColor.UserColor -> T.Data FrontendModel E2EHelper.BackendModel2 -> Result String ()
checkSavedColorIsNot unexpected state =
    case savedColor state of
        Just color ->
            if color == unexpected then
                Err "The backend is still holding the colour the user started with"

            else
                Ok ()

        Nothing ->
            Err "Expected the admin to exist on the backend"


savedColor : T.Data FrontendModel E2EHelper.BackendModel2 -> Maybe UserColor.UserColor
savedColor state =
    NonemptyDict.get Broadcast.adminUserId (E2EHelper.unwrapBackend state.backend).users
        |> Maybe.map .color
