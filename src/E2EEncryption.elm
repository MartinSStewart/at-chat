module E2EEncryption exposing (fileUploadTest, tests)

{-| End-to-end tests for encrypted DMs: agreeing to encrypt a conversation, working the
shared key out on each device, and sending a message once one is there.

The browser's half of the encryption port is stood in for rather than run, so nothing
here actually encrypts. What the stand-in gives back is what the app handed over, which
is enough to see that a message goes past the browser before it is sent and that what
reaches the server is the transformed version rather than what was typed.

-}

import Base64
import Broadcast
import Bytes exposing (Bytes)
import Bytes.Decode
import Bytes.Encode
import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import DmChannel
import DmChannelId
import E2EHelper exposing (BackendModel2)
import Effect.Browser.Dom as Dom
import Effect.Lamdera exposing (ClientId)
import Effect.Test as T
import Effect.Time as Time
import Encryption
import FileName
import FileStatus
import FrontendExtra
import Html.Attributes
import Id exposing (Id, UserId)
import IdArray
import Message exposing (MessageContent)
import NonemptyDict
import Pages.Guild
import RichText
import SeqDict
import Serialize
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)
import VisibleMessages
import X25519


tests :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
tests config =
    let
        warning : String
        warning =
            "If you lose it, you'll permanently lose access to all your encrypted messages."
    in
    [ E2EHelper.startTest
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
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ])
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")

                -- Encrypting anything needs a key pair on the account first, so that
                -- stands in front of enabling it.
                , admin.checkView
                    100
                    (Test.Html.Query.hasNot [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ])
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ])
                        , admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ])
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text Pages.Guild.waitingForE2eeText
                                , Test.Html.Selector.text E2EHelper.userName
                                , Test.Html.Selector.text Pages.Guild.toAcceptE2eeText
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
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.enterPrivateKeyText ])
                        , addPrivateKeyToAccount user
                            (\_ ->
                                [ user.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text Pages.Guild.enterPrivateKeyText ]
                                    )
                                , T.checkBackend 100 checkBothKeysStoredAndDifferent
                                , admin.click 100 (Dom.id "guild_cancelE2ee")
                                , user.checkView
                                    100
                                    (Test.Html.Query.hasNot
                                        [ Test.Html.Selector.text Pages.Guild.enterPrivateKeyText ]
                                    )
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ]
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
                                        , Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing)
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
    , E2EHelper.startTest
        "Decline a request to start end-to-end encryption"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.openDm admin 100 "2"
                , E2EHelper.openDm user 100 "0"
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\_ ->
                        [ admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.id "guild_cancelE2ee" ])

                        -- The request opens the section on its own, and the answer is
                        -- there to give straight away: no risks accepted, no key made.
                        , user.click 100 (Dom.id "guild_showMembers")
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.declineE2eeText ])
                        , user.click 100 (Dom.id "guild_declineE2ee")
                        , T.checkBackend 100 (checkDmE2eeDeclinedBy (Id.fromInt 2))

                        -- Whoever asked is told they were turned down, and the button to
                        -- ask is gone: the next word on it belongs to the other person.
                        , admin.checkView
                            100
                            (Test.Html.Query.has
                                [ Test.Html.Selector.text
                                    (E2EHelper.userName ++ " " ++ Pages.Guild.e2eeDeclinedText)
                                ]
                            )
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_cancelE2ee" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_enableE2ee" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ])
                        , E2EHelper.tallSnapshot admin 100 { name = "Encryption request was declined" }

                        -- The person who declined has nothing left waiting on them, so
                        -- their section closes again and has to be opened to go on.
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.declineE2eeText ])
                        , user.click 100 (Dom.id "guild_e2eeSection")
                        , user.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text Pages.Guild.youDeclinedE2eeText ])

                        -- Saying no isn't saying no forever. Asking is theirs to do now,
                        -- and it still costs them the same steps anybody pays.
                        , user.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ])
                        , user.click 100 (Dom.id "guild_e2eeAcceptRisks")
                        , addPrivateKeyToAccount user
                            (\_ ->
                                [ user.click 100 (Dom.id "guild_enableE2ee")
                                , T.checkBackend 100 (checkDmE2eeRequestedBy (Id.fromInt 2))
                                , user.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.id "guild_cancelE2ee" ])

                                -- The request goes the other way now, so the answer is
                                -- the admin's to give.
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text Pages.Guild.declineE2eeText ]
                                    )
                                , admin.checkView
                                    100
                                    (Test.Html.Query.hasNot
                                        [ Test.Html.Selector.text
                                            (E2EHelper.userName ++ " " ++ Pages.Guild.e2eeDeclinedText)
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
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
                                , respondToSharedSecretStored user Broadcast.adminUserId

                                -- Accepting reaches the other side, but the private key
                                -- was never kept, so that side has to be asked for it too.
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text (E2EHelper.userName ++ " " ++ Pages.Guild.requestAcceptedText) ]
                                    )
                                , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                                , respondToSharedSecretStored admin (Id.fromInt 2)
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
                                , respondToMessageEncrypted admin
                                , T.checkBackend 100 (checkEncryptedMessageStored "Hello in secret")

                                -- Without a key on this device the message is not sent,
                                -- and the draft is left alone so nothing is lost.
                                , E2EHelper.writeMessage admin 100 "This one cannot go"
                                , respondToEncryptionPortWithMissingKey admin
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
    , E2EHelper.startTest
        "Encrypt the messages written before a conversation was encrypted"
        E2EHelper.startTime
        config
        [ E2EHelper.connectTwoUsersAndJoinNewGuild
            E2EHelper.desktopWindow
            (\admin user ->
                [ E2EHelper.openDm admin 100 "2"
                , E2EHelper.openDm user 100 "0"

                -- A conversation nobody has encrypted yet, so the server can read all of
                -- it and both people's messages are stored as they were typed.
                , E2EHelper.writeMessage admin 100 writtenByAdmin
                , E2EHelper.writeMessage user 100 writtenByUser
                , T.checkBackend 100 (checkPlainTextMessageStored writtenByAdmin)
                , T.checkBackend 100 (checkPlainTextMessageStored writtenByUser)
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.click 100 (Dom.id "guild_enableE2ee")
                        , user.click 100 (Dom.id "guild_showMembers")
                        , user.click 100 (Dom.id "guild_e2eeAcceptRisks")
                        , addPrivateKeyToAccount user
                            (\userPrivateKey ->
                                [ user.input 100 (Dom.id "guild_e2eePrivateKey") userPrivateKey
                                , respondToSharedSecretStored user Broadcast.adminUserId
                                , T.checkBackend 100 checkDmIsEncrypted

                                -- Accepting is what turns encryption on, and the device
                                -- that does it is holding a key, so what the conversation
                                -- was keeping in the clear goes over straight away.
                                , respondToManyMessagesEncrypted user
                                , T.checkBackend 100 (checkNoPlainTextReachedTheServer writtenByAdmin)
                                , T.checkBackend 100 (checkNoPlainTextReachedTheServer writtenByUser)
                                , T.checkBackend 100 (checkEncryptedMessageStored writtenByAdmin)
                                , T.checkBackend 100 (checkEncryptedMessageStored writtenByUser)

                                -- Nothing was lost on the way: the conversation still
                                -- holds the same two messages.
                                , T.checkBackend 100 (checkEncryptedMessageCount 2)

                                -- The device that encrypted them read them out to do it,
                                -- so it goes on showing them without asking anything.
                                , user.click 100 (Dom.id "guild_hideMembers")
                                , user.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text writtenByAdmin ])
                                , user.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text writtenByUser ])

                                -- The admin's device is handed a key next and asks for the
                                -- same work over again, off what it still has loaded. The
                                -- server has had it done already and leaves it alone.
                                , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                                , respondToSharedSecretStored admin (Id.fromInt 2)
                                , respondToManyMessagesEncrypted admin
                                , T.checkBackend 100 (checkEncryptedMessageCount 2)
                                , T.checkBackend 100 (checkEncryptedMessageStored writtenByAdmin)
                                , admin.click 100 (Dom.id "guild_hideMembers")
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text writtenByAdmin ])
                                , admin.snapshotView 100 { name = "Older messages encrypted after the fact" }

                                -- A device that wasn't there when they were encrypted has
                                -- only the ciphertext to go on, so it reads what it is
                                -- given back through the browser in one go. Nothing else
                                -- checks that what the batch wrote is what the batch reads.
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
                                                        [ Id.fromInt 2 ]
                                                    )
                                                ]
                                            )
                                        , respondToManyMessagesDecrypted adminB
                                        , adminB.click 100 (Dom.id "guild_friendLabel_0")
                                        , adminB.checkView
                                            100
                                            (Test.Html.Query.has
                                                [ Test.Html.Selector.text writtenByUser ]
                                            )
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
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
                                , respondToSharedSecretStored userA Broadcast.adminUserId

                                -- That conversation is encrypted now, and the admin's
                                -- device has no key for it because their private key was
                                -- never kept anywhere.
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text (E2EHelper.userName ++ " " ++ Pages.Guild.requestAcceptedText) ]
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
                                        , respondToSharedSecretStored admin (Id.fromInt 3)
                                        , respondToSharedSecretStored admin (Id.fromInt 2)

                                        -- The conversation that was on screen stops
                                        -- asking for a key,
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.hasNot
                                                [ Test.Html.Selector.text Pages.Guild.missingPrivateKeyText ]
                                            )

                                        -- and so does the one that wasn't, where messages
                                        -- now go past the browser on the way out.
                                        , admin.click 100 (Dom.id "guild_hideMembers")
                                        , admin.click 100 (Dom.id "guild_friendLabel_2")
                                        , admin.click 100 (Dom.id "guild_showMembers")
                                        , admin.checkView
                                            100
                                            (Test.Html.Query.hasNot
                                                [ Test.Html.Selector.text Pages.Guild.missingPrivateKeyText ]
                                            )
                                        , admin.click 100 (Dom.id "guild_hideMembers")
                                        , E2EHelper.writeMessage admin 100 "Hello in secret"
                                        , T.checkBackend 100 (checkNoPlainTextReachedTheServer "Hello in secret")
                                        , respondToMessageEncrypted admin
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
    , E2EHelper.startTest
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
                , E2EHelper.writeMessage admin 100 "First message"
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text (Pages.Guild.enableE2eeText Nothing) ])
                        , admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.text Pages.Guild.toAcceptE2eeText ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot [ Test.Html.Selector.id "guild_cancelE2ee" ])
                        , admin.input 100 (Dom.id "guild_e2eePrivateKey") (String.dropRight 5 adminPrivateKey)
                        , T.checkState 100 (checkSharedSecretsAskedFor admin [])
                        , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                        , respondToSharedSecretStored admin Broadcast.adminUserId
                        , respondToManyMessagesEncrypted admin
                        , T.checkBackend 100 checkSoloDmIsEncrypted
                        , admin.checkView
                            100
                            (Test.Html.Query.has [ Test.Html.Selector.text "E2EE was enabled on" ])
                        , admin.checkView
                            100
                            (Test.Html.Query.hasNot
                                [ Test.Html.Selector.text Pages.Guild.missingPrivateKeyText ]
                            )
                        , admin.click 100 (Dom.id "guild_hideMembers")
                        , T.connectFrontend
                            100
                            E2EHelper.sessionId0
                            "/"
                            E2EHelper.desktopWindow
                            (\adminB ->
                                [ T.andThen 10
                                    (\data ->
                                        [ adminB.portEvent
                                            0
                                            "load_startup_data_from_js"
                                            (E2EHelper.startupDataJsonWithE2eeKeys
                                                data.time
                                                E2EHelper.firefoxDesktop
                                                [ E2EHelper.defaultAdminId ]
                                            )
                                        ]
                                    )
                                , writeEncryptedMessage admin 100 "Note to self"
                                , T.checkBackend 100 (checkSoloDmHasNoPlainText "Note to self")
                                , T.checkBackend 100 (checkSoloDmMessageStored "Note to self")
                                , respondToMessageDecrypted adminB
                                , adminB.checkView 100 (Test.Html.Query.has [ Test.Html.Selector.text "Note to self" ])

                                -- An edit goes past the browser the same way the message did,
                                -- so what reaches the server is the new ciphertext rather
                                -- than what was typed.
                                , editEncryptedMessage admin "Note to self" editedMessage
                                , T.checkBackend 100 (checkSoloDmHasNoPlainText editedMessage)
                                , T.checkBackend 100 (checkSoloDmMessageStored editedMessage)

                                -- Editing replaces the message rather than adding one.
                                , T.checkBackend 100 (checkSoloDmMessageCount 2)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Note to self" ])
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.exactText editedMessage ])

                                -- The other tab is told the message changed and has nothing
                                -- to show for it until it asks the browser what the new
                                -- ciphertext says.
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.text editedMessage ])
                                , respondToManyMessagesDecrypted adminB
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text editedMessage ])
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.hasNot [ Test.Html.Selector.exactText "Note to self" ])
                                , adminB.click 100 (Dom.id "guild_friendLabel_0")
                                , writeEncryptedMessage adminB 100 "Note to self from adminB"
                                , respondToMessageDecrypted admin
                                , adminB.snapshotView 100 { name = "Second tab views decrypted message" }
                                ]
                            )
                        , T.connectFrontend
                            100
                            E2EHelper.sessionId1
                            "/"
                            E2EHelper.desktopWindow
                            (\adminC ->
                                [ E2EHelper.handleLogin E2EHelper.firefoxDesktop E2EHelper.adminEmail adminC
                                , adminC.click 100 (Dom.id "guild_friendLabel_0")
                                , respondToManyMessagesDecryptedFailed adminC
                                , E2EHelper.writeMessage adminC 100 "Another session"
                                , adminC.click 100 (Dom.id "guild_showMembers")
                                , E2EHelper.tallSnapshot adminC 100 { name = "Enter private key on another device" }

                                -- Turning encryption off needs the key that reads the
                                -- messages, so a device without it isn't offered the
                                -- choice.
                                , adminC.checkView
                                    100
                                    (Test.Html.Query.hasNot
                                        [ Test.Html.Selector.text Pages.Guild.disableE2eeText ]
                                    )
                                , adminC.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                                , respondToSharedSecretStored adminC Broadcast.adminUserId
                                , adminC.click 100 (Dom.id "guild_e2eeSection")
                                , adminC.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text Pages.Guild.disableE2eeText ]
                                    )
                                , respondToManyMessagesDecrypted adminC
                                , writeEncryptedMessage adminC 100 "Note to self from adminB should be encrypted"
                                , respondToMessageDecrypted admin
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
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
                        , respondToSharedSecretStored admin Broadcast.adminUserId
                        , admin.click 100 (Dom.id "guild_hideMembers")
                        , writeEncryptedMessage admin 100 backlogMessage
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
                                , respondToManyMessagesDecrypted adminB
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
    , E2EHelper.startTest
        "Decrypt older messages loaded by scrolling up"
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
                        , respondToSharedSecretStored admin Broadcast.adminUserId
                        , admin.click 100 (Dom.id "guild_hideMembers")

                        -- More messages than fit in a page, so a device loading the
                        -- conversation gets the most recent ones and has to scroll up for
                        -- the rest.
                        , List.range 1 (VisibleMessages.pageSize + 5)
                            |> List.map (\index -> writeEncryptedMessage admin 100 (olderMessage index))
                            |> T.group
                        , T.checkBackend
                            100
                            (checkSoloDmMessageCount (VisibleMessages.pageSize + 5))
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
                                , adminB.click 100 (Dom.id "guild_friendLabel_0")
                                , respondToManyMessagesDecrypted adminB
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.exactText (olderMessage (VisibleMessages.pageSize + 5)) ]
                                    )
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.hasNot
                                        [ Test.Html.Selector.exactText (olderMessage 1) ]
                                    )
                                , T.checkState 100 (checkScrollShifts adminB 0)

                                -- Scrolling up loads the rest of the conversation. The
                                -- page arrives showing nothing at all, since nothing has
                                -- worked out what any of it says yet: the one shift here
                                -- is for the messages that were never encrypted, and it
                                -- moves the reader by nothing.
                                , E2EHelper.scrollToTop adminB
                                , adminB.checkView
                                    1000
                                    (Test.Html.Query.hasNot
                                        [ Test.Html.Selector.exactText (olderMessage 1) ]
                                    )
                                , T.checkState 100 (checkScrollShifts adminB 1)

                                -- The answer is what actually grows the conversation, so
                                -- the shift that keeps the reader in place belongs here.
                                , respondToManyMessagesDecrypted adminB
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.exactText (olderMessage 1) ]
                                    )
                                , T.checkState 100 (checkScrollShifts adminB 2)
                                , adminB.snapshotView 100 { name = "Older encrypted messages decrypted" }
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    , E2EHelper.startTest
        "Disable E2EE for a DM"
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
                , E2EHelper.writeMessage admin 100 backlogMessage
                , admin.click 100 (Dom.id "guild_showMembers")
                , admin.click 100 (Dom.id "guild_e2eeSection")
                , admin.click 100 (Dom.id "guild_e2eeAcceptRisks")
                , addPrivateKeyToAccount admin
                    (\adminPrivateKey ->
                        [ admin.click 100 (Dom.id "guild_enableE2ee")
                        , admin.input 100 (Dom.id "guild_e2eePrivateKey") adminPrivateKey
                        , respondToSharedSecretStored admin Broadcast.adminUserId
                        , respondToManyMessagesEncrypted admin
                        , T.checkBackend 100 checkSoloDmIsEncrypted
                        , T.checkBackend 100 (checkSoloDmHasNoPlainText backlogMessage)
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
                                , respondToManyMessagesDecrypted adminB
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text Pages.Guild.disableE2eeText ]
                                    )
                                , admin.click 100 (Dom.id "guild_disableE2ee")

                                -- The ciphertext the server hands back goes past the
                                -- browser to be read before the plain text is sent up.
                                , T.checkBackend 100 (checkSoloDmHasNoPlainText backlogMessage)
                                , respondToManyMessagesDecrypted admin
                                , T.checkBackend 100 checkSoloDmIsNotEncrypted
                                , T.checkBackend 100 (checkSoloDmPlainTextStored backlogMessage)
                                , T.checkBackend 100 (checkSoloDmMessageCount 0)
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text (Pages.Guild.enableE2eeText (Just ( E2EHelper.defaultAdminId, Time.millisToPosix 0 ))) ]
                                    )
                                , admin.checkView
                                    100
                                    (Test.Html.Query.has [ Test.Html.Selector.text backlogMessage ])

                                -- The other device is told encryption is off without
                                -- being sent any of the messages again.
                                , adminB.click 100 (Dom.id "guild_friendLabel_0")
                                , adminB.click 100 (Dom.id "guild_showMembers")
                                , adminB.click 100 (Dom.id "guild_e2eeSection")
                                , adminB.checkView
                                    100
                                    (Test.Html.Query.has
                                        [ Test.Html.Selector.text (Pages.Guild.enableE2eeText (Just ( E2EHelper.defaultAdminId, Time.millisToPosix 0 ))) ]
                                    )
                                , adminB.snapshotView 100 { name = "E2EE disabled" }
                                ]
                            )
                        ]
                    )
                ]
            )
        ]
    ]
        |> T.testGroup "E2EE"


{-| Attaching a file to an encrypted DM. The server has to end up with ciphertext and a
name it was never told, so what it is handed and what the message says about the file are
both checked.
-}
fileUploadTest :
    T.Config ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
fileUploadTest config =
    E2EHelper.startTest
        "Attach a file to an end-to-end encrypted DM"
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
                        , respondToSharedSecretStored admin Broadcast.adminUserId
                        , T.checkBackend 100 checkSoloDmIsEncrypted
                        , admin.click 100 (Dom.id "guild_hideMembers")

                        -- Nothing has been sent yet while the browser still has the file,
                        -- so deleting the attachment has to drop the ciphertext rather
                        -- than upload it once it arrives.
                        , admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                        , admin.click 100 (Dom.id "fileStatus_delete_1")
                        , respondToFileEncrypted admin
                        , T.checkState 100 (checkNothingUploadedYet admin.clientId)

                        -- Picking the file doesn't start the upload. The bytes go to the
                        -- browser first and only what comes back is sent.
                        , admin.click 100 (Dom.id "messageMenu_channelInput_uploadFile")
                        , T.checkState 100 (checkNothingUploadedYet admin.clientId)
                        , respondToFileEncrypted admin
                        , T.checkState 100 (checkCipherTextUploaded admin.clientId)
                        , T.backendUpdate
                            100
                            (Types.Rpc_GotFileUpload (FileStatus.fileHash "123123123") 1234 Nothing)

                        -- The browser fetches attached files itself, so the key has to be
                        -- left with it rather than handed over a request at a time.
                        , T.checkState 100 (checkFileKeysLeftWithBrowser 1 admin.clientId)
                        , E2EHelper.focusEvent
                            admin
                            1000
                            (Just (Dom.id "channel_textinput"))
                            (Just { start = 0, end = 0 })
                        , admin.keyDown 100 (Dom.id "channel_textinput") "Enter" []
                        , respondToMessageEncrypted admin
                        , T.checkBackend 100 checkAttachmentStoredEncrypted

                        -- Reading the message back gives the key again, which is how a
                        -- device that didn't upload the file gets hold of it.
                        , T.checkState 100 (checkFileKeysLeftWithBrowser 2 admin.clientId)
                        ]
                    )
                ]
            )
        ]


{-| Every file upload a client has made so far.
-}
fileUploads : ClientId -> T.Data FrontendModel BackendModel2 -> List T.HttpRequest
fileUploads clientId data =
    List.filter
        (\request ->
            String.endsWith "/file/upload-encrypted" request.url
                && (request.requestedBy == T.RequestedByFrontend clientId)
        )
        data.httpRequests


checkNothingUploadedYet : ClientId -> T.Data FrontendModel BackendModel2 -> Result String ()
checkNothingUploadedYet clientId data =
    if List.isEmpty (fileUploads clientId data) then
        Ok ()

    else
        Err "The file was uploaded before the browser had encrypted it"


{-| The bytes handed over to be encrypted are the ones the file picker gave, so putting
them through the stand-in cipher gives what the upload should have carried.
-}
checkCipherTextUploaded : ClientId -> T.Data FrontendModel BackendModel2 -> Result String ()
checkCipherTextUploaded clientId data =
    case
        ( List.filterMap encryptFileRequest (encryptionPortRequests clientId data)
        , fileUploads clientId data
        )
    of
        ( ( _, plainText ) :: _, [ upload ] ) ->
            case upload.body of
                T.BytesBody _ uploaded ->
                    if Base64.fromBytes uploaded == Base64.fromBytes (framedUpload plainText) then
                        Ok ()

                    else
                        Err "What was uploaded isn't the thumbnail and ciphertext the browser handed back"

                T.FileBody _ ->
                    Err "The file was uploaded as it was picked, without being encrypted first"

                _ ->
                    Err "The file was uploaded as something other than bytes"

        ( [], _ ) ->
            Err "The client didn't ask for a file to be encrypted"

        ( _, uploads ) ->
            Err
                ("Expected one file upload, found "
                    ++ String.fromInt (List.length uploads)
                )


{-| The body `/file/upload-encrypted` is sent: the thumbnail's length, then the thumbnail,
then the file.
-}
framedUpload : Bytes -> Bytes
framedUpload plainText =
    Bytes.Encode.sequence
        [ Bytes.Encode.unsignedInt32 Bytes.BE (Bytes.width stubThumbnail)
        , Bytes.Encode.bytes stubThumbnail
        , Bytes.Encode.bytes (stubCipherText plainText)
        ]
        |> Bytes.Encode.encode


checkAttachmentStoredEncrypted : BackendModel2 -> Result String ()
checkAttachmentStoredEncrypted backend =
    case soloDmChannel backend of
        Just dmChannel ->
            case IdArray.toList dmChannel.messages |> List.filterMap encryptedAttachedFiles |> List.concat of
                [ fileData ] ->
                    case fileData.isEncrypted of
                        FileStatus.IsEncrypted _ FileStatus.NoEncryptedThumbnail ->
                            Err "The message doesn't say the attached image has a thumbnail"

                        FileStatus.IsEncrypted _ FileStatus.HasEncryptedThumbnail ->
                            if FileName.toString fileData.fileName /= attachedFileName then
                                Err
                                    ("The file name in the message was lost. Stored: "
                                        ++ FileName.toString fileData.fileName
                                    )

                            else
                                case fileData.metadata of
                                    Just (FileStatus.FileMetadata_Image metadata) ->
                                        if metadata.imageSize == measuredImageSize then
                                            Ok ()

                                        else
                                            Err "The image size in the message isn't the one the browser measured"

                                    _ ->
                                        Err "The message doesn't say how big the attached image is"

                        FileStatus.IsNotEncrypted ->
                            Err "The message says the attached file isn't encrypted"

                [] ->
                    Err "No attached file reached the server"

                files ->
                    Err
                        ("Expected one attached file, found "
                            ++ String.fromInt (List.length files)
                        )

        Nothing ->
            Err "The DM the file was attached in isn't on the server"


encryptedAttachedFiles : Message.Message Id.ChannelMessageId (Id UserId) -> Maybe (List FileStatus.FileData)
encryptedAttachedFiles message =
    case message of
        Message.EncryptedUserTextMessage data ->
            case Base64.toBytes (Encryption.toBase64 data.content) of
                Just bytes ->
                    case stubPlainText bytes of
                        Ok contentAndEmbeds ->
                            SeqDict.values contentAndEmbeds.attachedFiles |> Just

                        Err _ ->
                            Nothing

                Nothing ->
                    Nothing

        _ ->
            Nothing


{-| The address the ciphertext ends up at only comes back with the upload, so the key is
worth nothing to the browser until then.
-}
checkFileKeysLeftWithBrowser : Int -> ClientId -> T.Data FrontendModel BackendModel2 -> Result String ()
checkFileKeysLeftWithBrowser expected clientId data =
    let
        stored : List { fileHash : String, key : Bytes }
        stored =
            List.filterMap storeFileKeysRequest (encryptionPortRequests clientId data) |> List.concat
    in
    if List.length stored /= expected then
        Err
            ("Expected "
                ++ String.fromInt expected
                ++ " file keys to have been left with the browser, found "
                ++ String.fromInt (List.length stored)
            )

    else if List.any (\key -> key.fileHash /= uploadedFileHash) stored then
        Err "A key was stored under something other than the file's hash"

    else if List.any (\key -> Base64.fromBytes key.key /= Base64.fromBytes stubFileKey) stored then
        Err "A key stored isn't the one the file was encrypted with"

    else
        Ok ()


storeFileKeysRequest :
    Encryption.ToJs (MessageContent (Id UserId))
    -> Maybe (List { fileHash : String, key : Bytes })
storeFileKeysRequest request =
    case request of
        Encryption.ToJs_StoreFileKeys keys ->
            Just keys

        _ ->
            Nothing


{-| What the test config's http handler reports back for an upload.
-}
uploadedFileHash : String
uploadedFileHash =
    "123123123"


respondToFileEncrypted :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToFileEncrypted client =
    T.andThen
        100
        (\data ->
            case List.filterMap encryptFileRequest (encryptionPortRequests client.clientId data) of
                ( requestId, plainText ) :: _ ->
                    [ Encryption.FromJs_FileEncrypted
                        requestId
                        { key = stubFileKey
                        , data = stubCipherText plainText
                        , thumbnail = Just stubThumbnail
                        , measured = Just (FileStatus.MeasuredImage measuredImageSize)
                        }
                        |> sendFromJs client
                    ]

                [] ->
                    [ T.checkState 0 (\_ -> Err "The client didn't ask for a file to be encrypted") ]
        )


encryptFileRequest :
    Encryption.ToJs (MessageContent (Id UserId))
    -> Maybe ( Id Encryption.EncryptFileRequestId, Bytes )
encryptFileRequest request =
    case request of
        Encryption.ToJs_EncryptFile { requestId, data } ->
            Just ( requestId, data )

        _ ->
            Nothing


{-| Stands in for the encrypted webp the browser makes of an image too big to show whole.
-}
stubThumbnail : Bytes
stubThumbnail =
    List.range 200 231
        |> List.map Bytes.Encode.unsignedInt8
        |> Bytes.Encode.sequence
        |> Bytes.Encode.encode


{-| Stands in for what the browser measures the attached image as. The server only ever
sees the ciphertext, so this is the only thing that can say how big it is.
-}
measuredImageSize : Coord CssPixels
measuredImageSize =
    Coord.xy 128 96


{-| Stands in for the 32 byte AES key the browser generates for each file.
-}
stubFileKey : Bytes
stubFileKey =
    List.range 0 31
        |> List.map Bytes.Encode.unsignedInt8
        |> Bytes.Encode.sequence
        |> Bytes.Encode.encode


{-| The name the file picker in the test config gives the file it hands over.
-}
attachedFileName : String
attachedFileName =
    "test-image.png"


checkDmE2eeDeclinedBy : Id UserId -> BackendModel2 -> Result String ()
checkDmE2eeDeclinedBy declinedBy backend =
    case adminDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeDeclinedBy actual) ->
            if actual == declinedBy then
                Ok ()

            else
                Err
                    ("Expected the DM to have been declined by user "
                        ++ String.fromInt (Id.toInt declinedBy)
                        ++ " but it was declined by user "
                        ++ String.fromInt (Id.toInt actual)
                    )

        _ ->
            Err "The declined request should have been recorded on the backend"


checkDmE2eeRequestedBy : Id UserId -> BackendModel2 -> Result String ()
checkDmE2eeRequestedBy requestedBy backend =
    case adminDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeRequestedBy ( actual, _ )) ->
            if actual == requestedBy then
                Ok ()

            else
                Err
                    ("Expected user "
                        ++ String.fromInt (Id.toInt requestedBy)
                        ++ " to have asked to encrypt the DM but user "
                        ++ String.fromInt (Id.toInt actual)
                        ++ " did"
                    )

        _ ->
            Err "Nobody has asked to encrypt the DM on the backend"


writtenByAdmin : String
writtenByAdmin =
    "Written before we encrypted anything"


writtenByUser : String
writtenByUser =
    "And this one was mine"


checkPlainTextMessageStored : String -> BackendModel2 -> Result String ()
checkPlainTextMessageStored text backend =
    case adminDmChannel backend of
        Just dmChannel ->
            if List.member text (plainTextMessages dmChannel) then
                Ok ()

            else
                Err
                    ("Expected the server to be holding \""
                        ++ text
                        ++ "\" as plain text. Holding: "
                        ++ String.join ", " (plainTextMessages dmChannel)
                    )

        Nothing ->
            Err "The DM isn't on the backend"


checkSharedSecretsAskedFor :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> List (Id UserId)
    -> T.Data FrontendModel BackendModel2
    -> Result String ()
checkSharedSecretsAskedFor client expected data =
    let
        sorted : List (Id UserId) -> String
        sorted ids =
            List.map Id.toInt ids |> List.sort |> List.map String.fromInt |> String.join ", "

        actual : List (Id UserId)
        actual =
            sharedSecretsAskedFor client.clientId data
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


checkDmIsEncrypted : BackendModel2 -> Result String ()
checkDmIsEncrypted backend =
    case adminDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeEnabled _) ->
            Ok ()

        _ ->
            Err "The DM should have been marked as encrypted on the backend"


checkPrivateKeyNeverReachedTheServer : String -> BackendModel2 -> Result String ()
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
                                RichText.toString Time.utc False SeqDict.empty data.content.content |> Just

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


checkNoPlainTextReachedTheServer : String -> BackendModel2 -> Result String ()
checkNoPlainTextReachedTheServer text backend =
    case adminDmChannel backend of
        Just dmChannel ->
            if List.any (String.contains text) (plainTextMessages dmChannel) then
                Err "The message reached the server as plain text"

            else
                Ok ()

        Nothing ->
            Ok ()


checkEncryptedMessageStored : String -> BackendModel2 -> Result String ()
checkEncryptedMessageStored text backend =
    if List.member text (encryptedMessageContents backend) then
        Ok ()

    else
        Err
            ("The stored message isn't what the browser handed back. Stored: "
                ++ String.join ", " (encryptedMessageContents backend)
            )


plainTextMessages : DmChannel.BackendDmChannel -> List String
plainTextMessages dmChannel =
    IdArray.toList dmChannel.messages
        |> List.filterMap
            (\message ->
                case message of
                    Message.UserTextMessage data ->
                        RichText.toString Time.utc False SeqDict.empty data.content.content |> Just

                    _ ->
                        Nothing
            )


encryptedMessageText : Message.Message Id.ChannelMessageId (Id UserId) -> Maybe String
encryptedMessageText message =
    case message of
        Message.EncryptedUserTextMessage data ->
            case Base64.toBytes (Encryption.toBase64 data.content) of
                Just bytes ->
                    case stubPlainText bytes of
                        Ok contentAndEmbeds ->
                            RichText.toString Time.utc False SeqDict.empty contentAndEmbeds.content |> Just

                        Err _ ->
                            Just "<not a message the test could read>"

                Nothing ->
                    Just "<not base64>"

        _ ->
            Nothing


checkEncryptedMessageCount : Int -> BackendModel2 -> Result String ()
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


encryptedMessageContents : BackendModel2 -> List String
encryptedMessageContents backend =
    case adminDmChannel backend of
        Just dmChannel ->
            IdArray.toList dmChannel.messages |> List.filterMap encryptedMessageText

        Nothing ->
            []


writeEncryptedMessage :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.DelayInMs
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
writeEncryptedMessage user delay text =
    T.group
        [ E2EHelper.writeMessage user delay text
        , respondToMessageEncrypted user
        ]


olderMessage : Int -> String
olderMessage index =
    "Message " ++ String.fromInt index


checkScrollShifts :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> Int
    -> T.Data FrontendModel BackendModel2
    -> Result String ()
checkScrollShifts client expected data =
    let
        actual : Int
        actual =
            E2EHelper.scrollShiftCount client.clientId data
    in
    if actual == expected then
        Ok ()

    else
        Err
            ("Expected the scroll to have been shifted "
                ++ String.fromInt expected
                ++ " times, was shifted "
                ++ String.fromInt actual
                ++ " times"
            )


{-| The same as `E2EHelper.editMostRecentMessageViaArrowUp` except that the browser has to
encrypt the edit before it is sent, so the new text only shows up once it has.
-}
editEncryptedMessage :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> String
    -> String
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
editEncryptedMessage user originalText editedText =
    T.group
        [ user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "editMessageTextInput" ])
        , user.keyDown 100 (Dom.id "channel_textinput") "ArrowUp" []

        -- The edit box opens pre-filled with what the message says, which for an encrypted
        -- one means what it decrypted to.
        , user.checkView
            100
            (Test.Html.Query.has
                [ Test.Html.Selector.id "editMessageTextInput"
                , Test.Html.Selector.attribute (Html.Attributes.value originalText)
                ]
            )
        , user.input 200 (Dom.id "editMessageTextInput") editedText
        , user.keyDown 100 (Dom.id "editMessageTextInput") "Enter" []
        , user.checkView 100 (Test.Html.Query.hasNot [ Test.Html.Selector.id "editMessageTextInput" ])
        , respondToMessageEncrypted user
        ]


editedMessage : String
editedMessage =
    "Note to self, corrected"


backlogMessage : String
backlogMessage =
    "Written before this device loaded"


checkSoloDmIsEncrypted : BackendModel2 -> Result String ()
checkSoloDmIsEncrypted backend =
    case soloDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeEnabled _) ->
            Ok ()

        _ ->
            Err "The DM with yourself should have been marked as encrypted on the backend"


checkSoloDmIsNotEncrypted : BackendModel2 -> Result String ()
checkSoloDmIsNotEncrypted backend =
    case soloDmChannel backend |> Maybe.map .e2ee of
        Just (DmChannel.E2eeDisabled _) ->
            Ok ()

        _ ->
            Err "The DM with yourself should no longer be marked as encrypted on the backend"


checkSoloDmPlainTextStored : String -> BackendModel2 -> Result String ()
checkSoloDmPlainTextStored text backend =
    case soloDmChannel backend of
        Just dmChannel ->
            if List.member text (plainTextMessages dmChannel) then
                Ok ()

            else
                Err
                    ("The message isn't stored as plain text. Stored: "
                        ++ String.join ", " (plainTextMessages dmChannel)
                    )

        Nothing ->
            Err "There's no DM with yourself on the backend"


checkSoloDmHasNoPlainText : String -> BackendModel2 -> Result String ()
checkSoloDmHasNoPlainText text backend =
    case soloDmChannel backend of
        Just dmChannel ->
            if List.any (String.contains text) (plainTextMessages dmChannel) then
                Err "The message reached the server as plain text"

            else
                Ok ()

        Nothing ->
            Ok ()


checkSoloDmMessageStored : String -> BackendModel2 -> Result String ()
checkSoloDmMessageStored text backend =
    if List.member text (soloDmEncryptedContents backend) then
        Ok ()

    else
        Err
            ("The stored message isn't what the browser handed back. Stored: "
                ++ String.join ", " (soloDmEncryptedContents backend)
            )


checkSoloDmMessageCount : Int -> BackendModel2 -> Result String ()
checkSoloDmMessageCount expected backend =
    let
        actual : Int
        actual =
            List.length (soloDmEncryptedContents backend)
    in
    if actual == expected then
        Ok ()

    else
        Err
            ("Expected "
                ++ String.fromInt expected
                ++ " encrypted messages in the DM with yourself, found "
                ++ String.fromInt actual
            )


soloDmEncryptedContents : BackendModel2 -> List String
soloDmEncryptedContents backend =
    case soloDmChannel backend of
        Just dmChannel ->
            IdArray.toList dmChannel.messages |> List.filterMap encryptedMessageText

        Nothing ->
            []


soloDmChannel : BackendModel2 -> Maybe DmChannel.BackendDmChannel
soloDmChannel backend =
    SeqDict.get
        (DmChannelId.fromUserIds (Id.fromInt 0) (Id.fromInt 0))
        (E2EHelper.unwrapBackend backend).dmChannels


adminDmChannel : BackendModel2 -> Maybe DmChannel.BackendDmChannel
adminDmChannel backend =
    SeqDict.get
        (DmChannelId.fromUserIds (Id.fromInt 0) (Id.fromInt 2))
        (E2EHelper.unwrapBackend backend).dmChannels


addPrivateKeyToAccount :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> (String -> List (T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
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


checkBothKeysStoredAndDifferent : BackendModel2 -> Result String ()
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


sharedSecretsAskedFor : ClientId -> T.Data FrontendModel BackendModel2 -> List (Id UserId)
sharedSecretsAskedFor clientId data =
    List.filterMap
        (\request ->
            case request of
                Encryption.ToJs_StoreSharedSecret { otherUserId } ->
                    Just otherUserId

                _ ->
                    Nothing
        )
        (encryptionPortRequests clientId data)


respondToSharedSecretStored :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> Id UserId
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToSharedSecretStored client otherUserId =
    Encryption.FromJs_SharedSecretStored otherUserId
        |> sendFromJs client


respondToMessageEncrypted :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToMessageEncrypted client =
    answerEncryptRequest
        client
        (\requestId contentAndEmbeds ->
            let
                bytes : Bytes
                bytes =
                    Serialize.encodeToBytesWithoutVersion Message.contentAndEmbedsCodec contentAndEmbeds
            in
            Encryption.FromJs_NewMessageEncrypted
                requestId
                (Encryption.encryptedData (stubCipherText bytes))
        )


respondToEncryptionPortWithMissingKey :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToEncryptionPortWithMissingKey client =
    answerEncryptRequest
        client
        (\requestId _ ->
            Encryption.FromJs_NewMessageEncryptFailed
                requestId
                "No encryption key is stored on this device for that conversation"
        )


respondToMessageDecrypted :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToMessageDecrypted client =
    T.andThen
        100
        (\data ->
            case List.filterMap decryptRequest (encryptionPortRequests client.clientId data) of
                ( requestId, bytes ) :: _ ->
                    case stubPlainText bytes of
                        Ok contentAndEmbeds ->
                            [ Encryption.FromJs_NewMessageDecrypted requestId contentAndEmbeds
                                |> sendFromJs client
                            ]

                        Err _ ->
                            [ T.checkState 0 (\_ -> Err "The bytes handed over to be decrypted aren't a message") ]

                [] ->
                    [ T.checkState 0 (\_ -> Err "The client didn't ask for a message to be decrypted") ]
        )


respondToManyMessagesDecrypted :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToManyMessagesDecrypted client =
    T.andThen
        100
        (\data ->
            case List.filterMap decryptManyRequest (encryptionPortRequests client.clientId data) of
                [] ->
                    [ T.checkState 0 (\_ -> Err "The client didn't ask for a conversation to be decrypted") ]

                requests ->
                    -- Every outstanding request is answered rather than whichever happens to
                    -- come first. A client can be waiting on more than one at a time, and
                    -- answering one it has already had back changes nothing.
                    List.map
                        (\( requestId, messages ) ->
                            List.map (\bytes -> stubPlainText bytes |> Result.mapError (\_ -> ())) messages
                                |> Encryption.FromJs_ManyMessagesDecrypted requestId
                                |> sendFromJs client
                        )
                        requests
        )


respondToManyMessagesDecryptedFailed :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToManyMessagesDecryptedFailed client =
    T.andThen
        100
        (\data ->
            case List.filterMap decryptManyRequest (encryptionPortRequests client.clientId data) of
                ( requestId, messages ) :: _ ->
                    [ List.map (\_ -> Err ()) messages
                        |> Encryption.FromJs_ManyMessagesDecrypted requestId
                        |> sendFromJs client
                    ]

                [] ->
                    [ T.checkState 0 (\_ -> Err "The client didn't ask for a conversation to be decrypted") ]
        )


respondToManyMessagesEncrypted :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
respondToManyMessagesEncrypted client =
    T.andThen
        100
        (\data ->
            case List.filterMap encryptManyRequest (encryptionPortRequests client.clientId data) of
                ( requestId, messages ) :: _ ->
                    [ List.map (\bytes -> Encryption.encryptedData (stubCipherText bytes)) messages
                        |> Encryption.FromJs_ManyMessagesEncrypted requestId
                        |> sendFromJs client
                    ]

                [] ->
                    [ T.checkState 0 (\_ -> Err "The client didn't ask for a conversation to be encrypted") ]
        )


encryptManyRequest :
    Encryption.ToJs (MessageContent (Id UserId))
    -> Maybe ( Id Encryption.EncryptManyRequestId, List Bytes )
encryptManyRequest request =
    case request of
        Encryption.ToJs_EncryptManyMessages { requestId, data } ->
            Just ( requestId, data )

        _ ->
            Nothing


decryptManyRequest :
    Encryption.ToJs (MessageContent (Id UserId))
    -> Maybe ( Id Encryption.DecryptManyRequestId, List Bytes )
decryptManyRequest request =
    case request of
        Encryption.ToJs_DecryptManyMessages { requestId, data } ->
            Just ( requestId, data )

        _ ->
            Nothing


stubCipherText : Bytes -> Bytes
stubCipherText payload =
    let
        iv : Int
        iv =
            stubIv payload
    in
    Bytes.Encode.sequence
        [ Bytes.Encode.unsignedInt32 Bytes.BE iv
        , Bytes.Encode.unsignedInt32 Bytes.BE iv
        , Bytes.Encode.unsignedInt32 Bytes.BE 0
        , Bytes.Encode.bytes payload
        ]
        |> Bytes.Encode.encode


stubIv : Bytes -> Int
stubIv payload =
    Bytes.Decode.decode
        (Bytes.Decode.loop
            ( Bytes.width payload, 0 )
            (\( bytesLeft, soFar ) ->
                if bytesLeft <= 0 then
                    Bytes.Decode.succeed (Bytes.Decode.Done soFar)

                else
                    Bytes.Decode.map
                        (\byte ->
                            Bytes.Decode.Loop
                                ( bytesLeft - 1, modBy 4294967296 (soFar * 31 + byte) )
                        )
                        Bytes.Decode.unsignedInt8
            )
        )
        payload
        |> Maybe.withDefault 0


{-| Reads a message back out of the stand-in ciphertext it was put into.
-}
stubPlainText : Bytes -> Result String (MessageContent (Id UserId))
stubPlainText cipherText =
    case
        Bytes.Decode.decode
            (Bytes.Decode.map2 (\_ rest -> rest)
                (Bytes.Decode.bytes 12)
                (Bytes.Decode.bytes (Bytes.width cipherText - 12))
            )
            cipherText
    of
        Just payload ->
            Serialize.decodeFromBytesWithoutVersion Message.contentAndEmbedsCodec payload
                |> Result.mapError (\_ -> "The bytes handed over to be decrypted aren't a message")

        Nothing ->
            Err "The bytes handed over to be decrypted aren't a message"


{-| Everything a client has asked the browser to do with encryption so far, most recent
first, which is the order `portBytesRequests` keeps them in.

The message being encrypted is decoded here too, since it is the only thing a reply needs
that isn't already in the request.

-}
encryptionPortRequests :
    ClientId
    -> T.Data FrontendModel BackendModel2
    -> List (Encryption.ToJs (MessageContent (Id UserId)))
encryptionPortRequests clientId data =
    List.filterMap
        (\request ->
            if request.clientId == clientId && request.portName == "encryption_to_js" then
                Serialize.decodeFromBytes
                    (Encryption.toJsCodec Message.contentAndEmbedsCodec)
                    request.value
                    |> Result.toMaybe

            else
                Nothing
        )
        data.portBytesRequests


answerEncryptRequest :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> (Id Encryption.EncryptRequestId -> MessageContent (Id UserId) -> Encryption.FromJs (MessageContent (Id UserId)))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
answerEncryptRequest client toReply =
    T.andThen
        100
        (\data ->
            case List.filterMap encryptRequest (encryptionPortRequests client.clientId data) of
                [] ->
                    [ T.checkState 0 (\_ -> Err "The client didn't ask for a message to be encrypted") ]

                requests ->
                    List.map
                        (\( requestId, contentAndEmbeds ) ->
                            toReply requestId contentAndEmbeds |> sendFromJs client
                        )
                        requests
        )


encryptRequest :
    Encryption.ToJs (MessageContent (Id UserId))
    -> Maybe ( Id Encryption.EncryptRequestId, MessageContent (Id UserId) )
encryptRequest request =
    case request of
        Encryption.ToJs_EncryptNewMessage { requestId, data } ->
            Just ( requestId, data )

        _ ->
            Nothing


decryptRequest :
    Encryption.ToJs (MessageContent (Id UserId))
    -> Maybe ( Id Encryption.DecryptRequestId, Bytes )
decryptRequest request =
    case request of
        Encryption.ToJs_DecryptNewMessage { requestId, data } ->
            Just ( requestId, data )

        _ ->
            Nothing


sendFromJs :
    T.FrontendActions ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
    -> Encryption.FromJs (MessageContent (Id UserId))
    -> T.Action ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel2
sendFromJs client fromJs =
    Serialize.encodeToBytes (Encryption.fromJsCodec Message.contentAndEmbedsCodec) fromJs
        |> client.portEventBytes 100 "encryption_from_js"
