module E2EEncryption exposing
    ( backlogDecryptedOnLoadTest
    , endToEndEncryptionAcceptTest
    , endToEndEncryptionRequestTest
    , oneKeySetsUpEveryConversationTest
    , soloDmEncryptionTest
    )

{-| End-to-end tests for encrypted DMs: agreeing to encrypt a conversation, working the
shared key out on each device, and sending a message once one is there.

The browser's half of the encryption port is stood in for rather than run, so nothing
here actually encrypts. What the stand-in gives back is what the app handed over, which
is enough to see that a message goes past the browser before it is sent and that what
reaches the server is the transformed version rather than what was typed.

-}

import Base64
import Broadcast
import DmChannel
import DmChannelId
import E2EHelper
import Effect.Browser.Dom as Dom
import Effect.Test as T
import Effect.Time as Time
import Encryption
import FrontendExtra
import Html.Attributes
import Id
import IdArray
import Message
import NonemptyDict
import Pages.Guild
import RichText
import SeqDict
import Serialize
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import X25519


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
                    (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.e2eeSectionTitle ])
                , admin.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.text warning ])
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text warning ])
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.enableE2eeText ])
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")

                -- Encrypting anything needs a key pair on the account first, so that
                -- stands in front of enabling it.
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.enableE2eeText ])
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.enableE2eeText ])
                        , admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.enableE2eeText ])
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
                                        [ Test.Html.Selector.text Pages.Guild.enableE2eeText ]
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
                                        , Test.Html.Selector.text Pages.Guild.enableE2eeText
                                        ]
                                    )

                                -- Sending your own private key to somebody hands them
                                -- everything encrypted to it, so it never leaves the
                                -- browser even when the sender pastes it into a message.
                                , admin.click 100 (Dom.id "guild_hideMembers")
                                , E2EHelper.writeMessage admin 100 ("here you go " ++ adminPrivateKey ++ " enjoy")
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "don't reveal your private key!" ]
                                    )
                                , admin.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.text adminPrivateKey ])
                                , T.checkBackend 100 (checkPrivateKeyNeverReachedTheServer adminPrivateKey)
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
                                , T.checkState 100 (checkSharedSecretsAskedFor user [])
                                , user.input 100 (Dom.id "guild_e2eePrivateKey") userPrivateKey
                                , E2EHelper.respondToSharedSecretStored user Broadcast.adminUserId

                                -- Accepting reaches the other side, but the private key
                                -- was never kept, so that side has to be asked for it too.
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "This conversation is missing a private key" ]
                                    )
                                , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                                , E2EHelper.respondToSharedSecretStored admin (Id.fromInt 2)
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
                                , E2EHelper.respondToMessageEncrypted admin
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


{-| A device that has no keys has none for any of its conversations, so being asked for
the same private key over and over, once per conversation, would be a poor way to set one
up. Typing it in once works out every shared secret the device is short of.
-}
oneKeySetsUpEveryConversationTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
oneKeySetsUpEveryConversationTest config =
    E2EHelper.startTest
        "One private key sets up every conversation on a device"
        E2EHelper.startTime
        config
        [ E2EHelper.connectFourUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin userA userB _ ->
                [ -- The admin asks the first of the others to encrypt, using the one key
                  -- pair their account has.
                  E2EHelper.openDm admin 100 "2"
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.click 100 (Dom.id "guild_enableE2ee")
                        , E2EHelper.openDm userA 100 "0"
                        , userA.click 100 (Dom.id "guild_showMembers")
                        , userA.click 100 (Dom.id "guild_e2eeAcceptRisks")
                        , addPrivateKeyToAccount userA
                            (\userAPrivateKey ->
                                [ userA.input 100 (Dom.id "guild_e2eePrivateKey") userAPrivateKey
                                , E2EHelper.respondToSharedSecretStored userA Broadcast.adminUserId

                                -- That conversation is encrypted now, and the admin's
                                -- device has no key for it because their private key was
                                -- never kept anywhere.
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text "This conversation is missing a private key" ]
                                    )

                                -- The second of the others asks the admin to encrypt,
                                -- which is a conversation the admin has no key for
                                -- either.
                                , E2EHelper.openDm userB 100 "0"
                                , userB.click 100 (Dom.id "guild_showMembers")
                                , userB.click 100 (Dom.id "guild_e2eeSection")
                                , userB.click 100 (Dom.id "guild_e2eeAcceptRisks")
                                , addPrivateKeyToAccount userB
                                    (\_ ->
                                        [ userB.click 100 (Dom.id "guild_enableE2ee")

                                        -- The admin answers in the conversation they were
                                        -- asked in, and types their key there.
                                        , admin.click 100 (Dom.id "guild_hideMembers")
                                        , admin.click 100 (Dom.id "guild_friendLabel_3")
                                        , admin.click 100 (Dom.id "guild_showMembers")
                                        , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey

                                        -- That one entry covered the other conversation
                                        -- as well, which was never on screen for it.
                                        , T.checkState
                                            100
                                            (checkSharedSecretsAskedFor admin [ Id.fromInt 2, Id.fromInt 3 ])
                                        , E2EHelper.respondToSharedSecretStored admin (Id.fromInt 3)
                                        , E2EHelper.respondToSharedSecretStored admin (Id.fromInt 2)

                                        -- The conversation that was on screen stops
                                        -- asking for a key,
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.hasNot
                                                [ Test.Html.Selector.text "This conversation is missing a private key" ]
                                            )

                                        -- and so does the one that wasn't, where messages
                                        -- now go past the browser on the way out.
                                        , admin.click 100 (Dom.id "guild_hideMembers")
                                        , admin.click 100 (Dom.id "guild_friendLabel_2")
                                        , admin.click 100 (Dom.id "guild_showMembers")
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.hasNot
                                                [ Test.Html.Selector.text "This conversation is missing a private key" ]
                                            )
                                        , admin.click 100 (Dom.id "guild_hideMembers")
                                        , E2EHelper.writeMessage admin 100 "Hello in secret"
                                        , T.checkBackend 100 (checkNoPlainTextReachedTheServer "Hello in secret")
                                        , E2EHelper.respondToMessageEncrypted admin
                                        , T.checkBackend 100 (checkEncryptedMessageStored "Hello in secret")
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]


{-| The conversations a client has asked the browser to work a shared secret out for.
Order doesn't matter, so both sides are sorted before comparing.
-}
checkSharedSecretsAskedFor :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> List (Id.Id Id.UserId)
    -> T.Data FrontendModel E2EHelper.BackendModel2
    -> Result String ()
checkSharedSecretsAskedFor client expected data =
    let
        sorted : List (Id.Id Id.UserId) -> String
        sorted ids =
            List.map Id.toInt ids |> List.sort |> List.map String.fromInt |> String.join ", "

        actual : List (Id.Id Id.UserId)
        actual =
            E2EHelper.sharedSecretsAskedFor client.clientId data
    in
    if sorted expected == sorted actual then
        Ok ()

    else
        Err
            ("Expected the browser to have been asked for shared secrets for ["
                ++ sorted expected
                ++ "], was asked for ["
                ++ sorted actual
                ++ "]"
            )


checkDmIsEncrypted : E2EHelper.BackendModel2 -> Result String ()
checkDmIsEncrypted backend =
    case adminDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeEnabled _) ->
            Ok ()

        _ ->
            Err "The DM should have been marked as encrypted on the backend"


{-| No message the server stored anywhere should contain the sender's private key, and
the one that tried to give it away should carry the warning in its place instead.
-}
checkPrivateKeyNeverReachedTheServer : String -> E2EHelper.BackendModel2 -> Result String ()
checkPrivateKeyNeverReachedTheServer privateKeyText backend =
    let
        messages : List String
        messages =
            SeqDict.values (E2EHelper.unwrapBackend backend).dmChannels
                |> List.concatMap (\dmChannel -> IdArray.toList dmChannel.messages)
                |> List.filterMap
                    (\message ->
                        case message of
                            Message.UserTextMessage data ->
                                RichText.toString Time.utc False SeqDict.empty data.content |> Just

                            _ ->
                                Nothing
                    )
    in
    if List.any (String.contains privateKeyText) messages then
        Err "The private key reached the server"

    else if List.any (String.contains "don't reveal your private key!") messages then
        Ok ()

    else
        Err
            ("The message that tried to give the key away isn't on the server at all. Stored: "
                ++ String.join " | " messages
            )


{-| The server should never have been handed the message as it was typed. An encrypted
conversation only ever stores EncryptedUserTextMessage, so a plain one carrying the text
means it went out before the browser had it.
-}
checkNoPlainTextReachedTheServer : String -> E2EHelper.BackendModel2 -> Result String ()
checkNoPlainTextReachedTheServer text backend =
    case adminDmChannel backend of
        Just dmChannel ->
            if List.any (String.contains text) (plainTextMessages dmChannel) then
                Err "The message reached the server as plain text"

            else
                Ok ()

        Nothing ->
            Ok ()


checkEncryptedMessageStored : String -> E2EHelper.BackendModel2 -> Result String ()
checkEncryptedMessageStored text backend =
    if List.member text (encryptedMessageContents backend) then
        Ok ()

    else
        Err
            ("The stored message isn't what the browser handed back. Stored: "
                ++ String.join ", " (encryptedMessageContents backend)
            )


{-| What every plain message in a channel says.
-}
plainTextMessages : DmChannel.DmChannel -> List String
plainTextMessages dmChannel =
    IdArray.toList dmChannel.messages
        |> List.filterMap
            (\message ->
                case message of
                    Message.UserTextMessage data ->
                        RichText.toString Time.utc False SeqDict.empty data.content |> Just

                    _ ->
                        Nothing
            )


{-| What every encrypted message in a channel says. The stand-in for encryption leaves
the message serialized but readable, which is what lets a test see whether what reached
the server is what the app handed over rather than what was typed.
-}
encryptedMessageText : Message.Message Id.ChannelMessageId (Id.Id Id.UserId) -> Maybe String
encryptedMessageText message =
    case message of
        Message.EncryptedUserTextMessage data ->
            case Base64.toBytes (Encryption.toBase64 data.encryptedData) of
                Just bytes ->
                    case Serialize.decodeFromBytes Message.contentAndEmbedsCodec bytes of
                        Ok contentAndEmbeds ->
                            RichText.toString Time.utc False SeqDict.empty contentAndEmbeds.content |> Just

                        Err _ ->
                            Just "<not a message the test could read>"

                Nothing ->
                    Just "<not base64>"

        _ ->
            Nothing


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
            IdArray.toList dmChannel.messages |> List.filterMap encryptedMessageText

        Nothing ->
            []


soloDmEncryptionTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
soloDmEncryptionTest config =
    E2EHelper.startTest
        "Encrypt a DM with yourself"
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
                , admin.click 100 (Dom.id "guild_openChannel_0")
                , E2EHelper.openDm admin 100 "0"
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.enableE2eeText ])
                        , admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text "to accept message encryption" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_cancelE2ee" ])
                        , admin.input 100 (Dom.id "guild_e2eePrivateKey") (String.dropRight 5 adminPrivateKey)
                        , T.checkState 100 (checkSharedSecretsAskedFor admin [])
                        , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                        , E2EHelper.respondToSharedSecretStored admin Broadcast.adminUserId
                        , T.checkBackend 100 checkSoloDmIsEncrypted
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "E2EE was enabled on" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.text "This conversation is missing a private key" ]
                            )
                        , admin.click 100 (Dom.id "guild_hideMembers")
                        , T.connectFrontend
                            100
                            E2EHelper.sessionId0
                            "/"
                            E2EHelper.desktopWindow
                            (\adminB ->
                                [ T.andThen 10 (\data -> [ adminB.portEvent 0 "load_startup_data_from_js" (E2EHelper.startupDataJson data.time E2EHelper.firefoxDesktop) ])
                                , E2EHelper.writeMessage admin 100 "Note to self"
                                , T.checkBackend 100 (checkSoloDmHasNoPlainText "Note to self")
                                , E2EHelper.respondToMessageEncrypted admin
                                , T.checkBackend 100 (checkSoloDmMessageStored "Note to self")
                                , E2EHelper.respondToMessageDecrypted adminB
                                , adminB.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Note to self" ])
                                , adminB.click 100 (Dom.id "guild_friendLabel_0")
                                , adminB.snapshotView 100 { name = "Second tab views decrypted message" }
                                ]
                            )
                        ]
                    )
                ]
            )
        ]


{-| A device that already has the key for a conversation has to work out what the
messages waiting in it say, since only their encrypted form is kept anywhere. That is the
whole conversation at once rather than one request per message, so the page asks for the
backlog as it loads and fills the contents in when the answer comes back.
-}
backlogDecryptedOnLoadTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg E2EHelper.BackendModel2
backlogDecryptedOnLoadTest config =
    E2EHelper.startTest
        "Decrypt the messages already in a conversation when the page loads"
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
                , admin.click 100 (Dom.id "guild_openChannel_0")
                , E2EHelper.openDm admin 100 "0"
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                        , E2EHelper.respondToSharedSecretStored admin Broadcast.adminUserId
                        , admin.click 100 (Dom.id "guild_hideMembers")
                        , E2EHelper.writeMessage admin 100 backlogMessage
                        , E2EHelper.respondToMessageEncrypted admin
                        , T.checkBackend 100 (checkSoloDmHasNoPlainText backlogMessage)

                        -- A second device with the key for this conversation loads with
                        -- the message already sitting in it.
                        , T.connectFrontend
                            100
                            E2EHelper.sessionId0
                            "/"
                            E2EHelper.desktopWindow
                            (\adminB ->
                                [ T.andThen
                                    10
                                    (\data ->
                                        [ adminB.portEvent
                                            0
                                            "load_startup_data_from_js"
                                            (E2EHelper.startupDataJsonWithE2eeKeys
                                                data.time
                                                E2EHelper.firefoxDesktop
                                                [ Broadcast.adminUserId ]
                                            )
                                        ]
                                    )
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.text backlogMessage ])
                                , E2EHelper.respondToManyMessagesDecrypted adminB
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text backlogMessage ])
                                , adminB.click 100 (Dom.id "guild_friendLabel_0")
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text backlogMessage ])
                                , adminB.snapshotView 100 { name = "Backlog decrypted on page load" }
                                ]
                            )
                        ]
                    )
                ]
            )
        ]


backlogMessage : String
backlogMessage =
    "Written before this device loaded"


checkSoloDmIsEncrypted : E2EHelper.BackendModel2 -> Result String ()
checkSoloDmIsEncrypted backend =
    case soloDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeEnabled _) ->
            Ok ()

        _ ->
            Err "The DM with yourself should have been marked as encrypted on the backend"


checkSoloDmHasNoPlainText : String -> E2EHelper.BackendModel2 -> Result String ()
checkSoloDmHasNoPlainText text backend =
    case soloDmChannel backend of
        Just dmChannel ->
            if List.any (String.contains text) (plainTextMessages dmChannel) then
                Err "The message reached the server as plain text"

            else
                Ok ()

        Nothing ->
            Ok ()


checkSoloDmMessageStored : String -> E2EHelper.BackendModel2 -> Result String ()
checkSoloDmMessageStored text backend =
    if List.member text (soloDmEncryptedContents backend) then
        Ok ()

    else
        Err
            ("The stored message isn't what the browser handed back. Stored: "
                ++ String.join ", " (soloDmEncryptedContents backend)
            )


soloDmEncryptedContents : E2EHelper.BackendModel2 -> List String
soloDmEncryptedContents backend =
    case soloDmChannel backend of
        Just dmChannel ->
            IdArray.toList dmChannel.messages |> List.filterMap encryptedMessageText

        Nothing ->
            []


soloDmChannel : E2EHelper.BackendModel2 -> Maybe DmChannel.DmChannel
soloDmChannel backend =
    SeqDict.get
        (DmChannelId.fromUserIds (Id.fromInt 0) (Id.fromInt 0))
        (E2EHelper.unwrapBackend backend).dmChannels


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
                [ Test.Html.Selector.text FrontendExtra.savePrivateKeyTitle
                , Test.Html.Selector.text "It is not stored anywhere else"
                , Test.Html.Selector.id "frontend_newPrivateKey_copy"
                ]
            )
        , client.click 100 (Dom.id "frontend_newPrivateKey_copy")
        , T.andThen
            100
            (\data ->
                case E2EHelper.copiedText client.clientId data of
                    Just privateKeyText ->
                        client.click 100 (Dom.id "frontend_closeNewPrivateKey")
                            :: client.checkView
                                100
                                (Test.Html.Query.hasNot
                                    [ Test.Html.Selector.text FrontendExtra.savePrivateKeyTitle ]
                                )
                            :: continueWith privateKeyText

                    Nothing ->
                        [ T.checkState 0 (\_ -> Err "The copy button didn't put the private key on the clipboard") ]
            )
        ]


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
