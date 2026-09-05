module MessageDropdown exposing
    ( addStickerOrEmojiText
    , addTimestampText
    , discordUserDropdownList
    , emojiDropdownList
    , mentionUserText
    , pressedArrowInDropdown
    , pressedDropdownItem
    , userDropdownList
    , view
    )

import Array
import CustomEmoji
import Discord
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Effect.Command as Command exposing (Command, FrontendOnly)
import Effect.Task as Task
import Effect.Time as Time
import Emoji exposing (CachedEmojiData, EmojiOrSticker(..), SkinTone)
import Html.Events
import Id exposing (AnyGuildOrDmId(..), CustomEmojiId, DiscordGuildOrDmId(..), GuildOrDmId(..), Id, StickerId, UserId)
import Json.Decode
import LinkedAndOtherDiscordUsers
import List.Extra
import List.Nonempty
import LocalState exposing (LocalState)
import MembersAndOwner
import MessageInput exposing (MentionUserDropdown, Msg(..), NameSoFar(..), NameSoFarData, TimestampData(..))
import MessageMenu
import MyUi
import NonemptyDict
import PersonName
import Ports
import Range exposing (Range)
import RichText
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Sticker
import String.Nonempty exposing (NonemptyString)
import TimeInMinutes exposing (TimeInMinutes)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import User exposing (FrontendUser, LocalUser)
import UserSession exposing (DiscordFrontendUser)


mentionUserText : String
mentionUserText =
    "Mention a user"


addStickerOrEmojiText : String
addStickerOrEmojiText =
    "Add a sticker or emoji"


addTimestampText : String
addTimestampText =
    "Add a timestamp"


pressedArrowInDropdown :
    Bool
    -> Time.Zone
    -> Time.Posix
    -> NameSoFar
    -> AnyGuildOrDmId
    -> Int
    -> Maybe MentionUserDropdown
    -> Maybe CachedEmojiData
    -> LocalState
    -> Maybe MentionUserDropdown
pressedArrowInDropdown isMobile timezone time nameSoFar guildOrDmId index maybePingUser emojiData local =
    case maybePingUser of
        Just pingUser ->
            let
                helper : Int -> Maybe MentionUserDropdown
                helper dropdownListLength =
                    { pingUser
                        | dropdownIndex =
                            if index < 0 then
                                dropdownListLength - 1

                            else if index >= dropdownListLength then
                                0

                            else
                                index
                    }
                        |> Just
            in
            case nameSoFar of
                NameSoFar nameSoFarData ->
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            userDropdownList isMobile nameSoFarData guildOrDmId2 local |> List.length |> helper

                        DiscordGuildOrDmId guildOrDmId2 ->
                            discordUserDropdownList isMobile nameSoFarData guildOrDmId2 local |> List.length |> helper

                EmojiSoFar emojiSoFar ->
                    case emojiData of
                        Just emojiData2 ->
                            let
                                ( availableCustomEmojis, availableStickers ) =
                                    MessageMenu.availableCustomEmojisAndStickers guildOrDmId local
                            in
                            emojiDropdownList
                                isMobile
                                emojiSoFar
                                availableCustomEmojis
                                availableStickers
                                local.localUser
                                emojiData2
                                |> List.length
                                |> helper

                        Nothing ->
                            Nothing

                TimestampSoFar _ timestampData ->
                    timestampDropdownList timezone time timestampData |> List.length |> helper

        Nothing ->
            Nothing


userDropdownList : Bool -> NameSoFarData -> GuildOrDmId -> LocalState -> List ( Id UserId, FrontendUser )
userDropdownList isMobile nameSoFar guildOrDmId local =
    let
        allUsers : SeqDict (Id UserId) FrontendUser
        allUsers =
            User.allUsers local.localUser
    in
    (case guildOrDmId of
        GuildOrDmId_Guild { guildId } ->
            case SeqDict.get guildId local.guilds of
                Just guild ->
                    MembersAndOwner.membersAndOwner guild.membersAndOwner

                Nothing ->
                    []

        GuildOrDmId_Dm { otherUserId } ->
            if local.localUser.session.userId == otherUserId then
                [ otherUserId ]

            else
                [ local.localUser.session.userId, otherUserId ]
    )
        |> List.filterMap
            (\userId ->
                case SeqDict.get userId allUsers of
                    Just user ->
                        if String.startsWith nameSoFar.nameSoFar (PersonName.toString user.name) then
                            Just ( userId, user )

                        else
                            Nothing

                    Nothing ->
                        Nothing
            )
        |> List.sortBy (\( _, user ) -> PersonName.toString user.name)
        |> List.take (maxDropdownUsers isMobile)


maxDropdownUsers : Bool -> number
maxDropdownUsers isMobile =
    if isMobile then
        5

    else
        10


emojiDropdownList :
    Bool
    -> NameSoFarData
    -> SeqSet (Id CustomEmojiId)
    -> SeqSet (Id StickerId)
    -> LocalUser
    -> CachedEmojiData
    -> List EmojiOrSticker
emojiDropdownList isMobile nameSoFar availableCustomEmojis availableStickers localUser emojiData =
    let
        substring =
            String.toLower nameSoFar.nameSoFar
    in
    if String.length substring > 2 then
        let
            unicodeEmojis : List ( Int, EmojiOrSticker )
            unicodeEmojis =
                Array.filter (\item -> String.contains substring item.shortName) emojiData.shortNames
                    |> Array.toList
                    |> List.map (\a -> ( String.length a.shortName, EmojiOrSticker_UnicodeEmoji a.emoji ))

            customEmojis : List ( Int, EmojiOrSticker )
            customEmojis =
                List.filterMap
                    (\customEmojiId ->
                        case SeqDict.get customEmojiId localUser.customEmojis of
                            Just customEmoji ->
                                let
                                    name =
                                        CustomEmoji.emojiNameToString customEmoji.name
                                in
                                if String.contains substring (String.toLower name) then
                                    Just ( String.length name, EmojiOrSticker_CustomEmoji customEmojiId )

                                else
                                    Nothing

                            Nothing ->
                                Nothing
                    )
                    (SeqSet.toList availableCustomEmojis)

            stickers : List ( Int, EmojiOrSticker )
            stickers =
                List.filterMap
                    (\stickerId ->
                        case SeqDict.get stickerId localUser.stickers of
                            Just sticker ->
                                if String.contains substring (String.toLower sticker.name) then
                                    Just ( String.length sticker.name, EmojiOrSticker_Sticker stickerId )

                                else
                                    Nothing

                            Nothing ->
                                Nothing
                    )
                    (SeqSet.toList availableStickers)
        in
        (unicodeEmojis ++ customEmojis ++ stickers)
            |> List.sortBy Tuple.first
            |> List.take (maxDropdownUsers isMobile)
            |> List.map Tuple.second

    else
        []


discordUserDropdownList : Bool -> NameSoFarData -> DiscordGuildOrDmId -> LocalState -> List ( Discord.Id Discord.UserId, DiscordFrontendUser )
discordUserDropdownList isMobile nameSoFar guildOrDmId local =
    let
        allUsers : SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
        allUsers =
            LinkedAndOtherDiscordUsers.allDiscordUsers local.localUser.discordUsers
    in
    (case guildOrDmId of
        DiscordGuildOrDmId_Guild { guildId } ->
            case SeqDict.get guildId local.discordGuilds of
                Just guild ->
                    MembersAndOwner.membersAndOwner guild.membersAndOwner

                Nothing ->
                    []

        DiscordGuildOrDmId_Dm data ->
            case SeqDict.get data.channelId local.discordDmChannels of
                Just channel ->
                    NonemptyDict.keys channel.members |> List.Nonempty.toList

                Nothing ->
                    []
    )
        |> List.filterMap
            (\userId ->
                case SeqDict.get userId allUsers of
                    Just user ->
                        if String.startsWith nameSoFar.nameSoFar (PersonName.toString user.name) then
                            Just ( userId, user )

                        else
                            Nothing

                    Nothing ->
                        Nothing
            )
        |> List.sortBy (\( _, user ) -> PersonName.toString user.name)
        |> List.take (maxDropdownUsers isMobile)


timestampDropdownList : Time.Zone -> Time.Posix -> TimestampData -> List TimeInMinutes
timestampDropdownList timezone time timestamp =
    let
        helper scale value =
            [ toFloat (Time.posixToMillis time // (60 * 1000)) + scale * value |> round |> TimeInMinutes.fromMinutes
            , toFloat (Time.posixToMillis time // (60 * 1000)) - scale * value |> round |> TimeInMinutes.fromMinutes
            ]
    in
    case timestamp of
        WeekOffset value ->
            helper (60 * 24 * 7) value

        DayOffset value ->
            helper (60 * 24) value

        HourOffset value ->
            helper 60 value

        MinuteOffset value ->
            helper 1 value

        TimeOfDay { hours, minutes } ->
            let
                sinceStartOfDayMs : Int
                sinceStartOfDayMs =
                    (Time.toHour timezone time * 60 * 60 * 1000)
                        + (Time.toMinute timezone time * 60 * 1000)
                        + (Time.toSecond timezone time * 1000)
                        + Time.toMillis timezone time

                startOfDay : Int
                startOfDay =
                    (Time.posixToMillis time - sinceStartOfDayMs) // (60 * 1000)
            in
            [ startOfDay + hours * 60 + minutes |> TimeInMinutes.fromMinutes
            , startOfDay + (hours + 12) * 60 + minutes |> TimeInMinutes.fromMinutes
            , startOfDay + (hours + 24) * 60 + minutes |> TimeInMinutes.fromMinutes
            , startOfDay + (hours + 36) * 60 + minutes |> TimeInMinutes.fromMinutes
            ]


pressedDropdownItem :
    msg
    -> Bool
    -> Time.Posix
    -> NameSoFar
    -> AnyGuildOrDmId
    -> HtmlId
    -> Int
    -> Maybe MentionUserDropdown
    -> Maybe CachedEmojiData
    -> LocalState
    -> NonemptyString
    -> ( Maybe MentionUserDropdown, NonemptyString, Command FrontendOnly toMsg msg )
pressedDropdownItem setFocusMsg isMobile time nameSoFar guildOrDmId channelTextInputId dropdownIndex pingUser emojiData local inputText =
    let
        maybeTextToInsert : Maybe ( Range, String )
        maybeTextToInsert =
            case nameSoFar of
                NameSoFar nameSoFarData ->
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            case
                                userDropdownList isMobile nameSoFarData guildOrDmId2 local
                                    |> List.Extra.getAt dropdownIndex
                            of
                                Just ( _, user ) ->
                                    ( { start = nameSoFarData.index
                                      , end = nameSoFarData.index + String.length nameSoFarData.nameSoFar
                                      }
                                    , PersonName.toString user.name
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        DiscordGuildOrDmId guildOrDmId2 ->
                            case
                                discordUserDropdownList isMobile nameSoFarData guildOrDmId2 local
                                    |> List.Extra.getAt dropdownIndex
                            of
                                Just ( _, user ) ->
                                    ( { start = nameSoFarData.index
                                      , end = nameSoFarData.index + String.length nameSoFarData.nameSoFar
                                      }
                                    , PersonName.toString user.name
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                EmojiSoFar emojiSoFar ->
                    case emojiData of
                        Just emojiData2 ->
                            let
                                ( availableCustomEmojis, availableStickers ) =
                                    MessageMenu.availableCustomEmojisAndStickers guildOrDmId local
                            in
                            case
                                emojiDropdownList isMobile emojiSoFar availableCustomEmojis availableStickers local.localUser emojiData2
                                    |> List.Extra.getAt dropdownIndex
                            of
                                Just emojiOrSticker ->
                                    ( { start = emojiSoFar.index - 1
                                      , end = emojiSoFar.index + String.length emojiSoFar.nameSoFar
                                      }
                                    , case emojiOrSticker of
                                        EmojiOrSticker_UnicodeEmoji emoji ->
                                            Emoji.emojiWithSkinTone local.localUser.user.emojiConfig.skinTone emoji emojiData2

                                        EmojiOrSticker_Sticker stickerId ->
                                            Sticker.idToString stickerId

                                        EmojiOrSticker_CustomEmoji customEmojiId ->
                                            CustomEmoji.idToString customEmojiId
                                    )
                                        |> Just

                                Nothing ->
                                    Nothing

                        Nothing ->
                            Nothing

                TimestampSoFar range timestampData ->
                    case timestampDropdownList local.localUser.timezone time timestampData |> List.Extra.getAt dropdownIndex of
                        Just timestamp ->
                            ( range, RichText.dateAndTimeToString local.localUser.timezone timestamp ) |> Just

                        Nothing ->
                            Nothing
    in
    case ( pingUser, maybeTextToInsert ) of
        ( Just _, Just ( range, textToInsert ) ) ->
            ( Nothing
            , inputText
            , Command.batch
                [ Dom.focus channelTextInputId
                    |> Task.attempt (\_ -> setFocusMsg)
                , Ports.execCommand
                    { htmlId = channelTextInputId
                    , commands = [ Ports.InsertText (textToInsert ++ " ") range ]
                    }
                ]
            )

        _ ->
            ( Nothing, inputText, Command.none )


view :
    Bool
    -> Time.Posix
    -> NameSoFar
    -> AnyGuildOrDmId
    -> Maybe SkinTone
    -> Maybe CachedEmojiData
    -> LocalState
    -> (Int -> HtmlId)
    -> MentionUserDropdown
    -> Element Msg
view isMobile time nameSoFar guildOrDmId skinTone emojiData local dropdownButtonId dropdown =
    case nameSoFar of
        NameSoFar nameSoFarData ->
            let
                rows : List (Element Msg)
                rows =
                    case guildOrDmId of
                        GuildOrDmId guildOrDmId2 ->
                            List.indexedMap
                                (\index ( _, user ) ->
                                    dropdownButton
                                        isMobile
                                        False
                                        dropdown
                                        dropdownButtonId
                                        index
                                        (Ui.text (PersonName.toString user.name))
                                )
                                (userDropdownList isMobile nameSoFarData guildOrDmId2 local)

                        DiscordGuildOrDmId guildOrDmId2 ->
                            List.indexedMap
                                (\index ( _, user ) ->
                                    dropdownButton
                                        isMobile
                                        False
                                        dropdown
                                        dropdownButtonId
                                        index
                                        (Ui.text (PersonName.toString user.name))
                                )
                                (discordUserDropdownList isMobile nameSoFarData guildOrDmId2 local)

                dropdownViewHeight : Int
                dropdownViewHeight =
                    List.length rows * dropdownButtonHeight isMobile False
            in
            dropdownContainer nameSoFar dropdown dropdownViewHeight rows

        EmojiSoFar emojiSoFar ->
            case emojiData of
                Just emojiData2 ->
                    let
                        ( availableCustomEmojis, availableStickers ) =
                            MessageMenu.availableCustomEmojisAndStickers guildOrDmId local

                        ( rows, _, height ) =
                            List.foldl
                                (\emojiOrSticker ( rows2, index, height2 ) ->
                                    let
                                        helper isLarge content =
                                            ( dropdownButton
                                                isMobile
                                                isLarge
                                                dropdown
                                                dropdownButtonId
                                                index
                                                content
                                                :: rows2
                                            , index + 1
                                            , height2 + dropdownButtonHeight isMobile isLarge
                                            )
                                    in
                                    case emojiOrSticker of
                                        EmojiOrSticker_UnicodeEmoji emoji ->
                                            Ui.row
                                                [ Ui.spacing 8 ]
                                                [ Ui.el
                                                    [ Ui.Font.size 24, Ui.width Ui.shrink ]
                                                    (Ui.text (Emoji.emojiWithSkinTone skinTone emoji emojiData2))
                                                , case SeqDict.get emoji emojiData2.emojis of
                                                    Just emoji2 ->
                                                        Ui.row
                                                            [ Ui.spacing 8 ]
                                                            (List.map (\shortName -> Ui.text (":" ++ shortName ++ ":")) emoji2.shortNames)

                                                    Nothing ->
                                                        Ui.none
                                                ]
                                                |> helper False

                                        EmojiOrSticker_Sticker stickerId ->
                                            case SeqDict.get stickerId local.localUser.stickers of
                                                Just sticker ->
                                                    Ui.row
                                                        [ Ui.spacing 8 ]
                                                        [ Sticker.viewHelper
                                                            (String.fromInt (dropdownButtonHeight isMobile True) ++ "px")
                                                            sticker
                                                            Sticker.LoopForever
                                                            |> Ui.html
                                                        , Ui.text (":" ++ sticker.name ++ ":")
                                                        ]
                                                        |> helper True

                                                Nothing ->
                                                    Ui.el [ Ui.Font.size 24, Ui.Font.italic ] (Ui.text "Sticker missing")
                                                        |> helper False

                                        EmojiOrSticker_CustomEmoji customEmojiId ->
                                            case SeqDict.get customEmojiId local.localUser.customEmojis of
                                                Just emoji ->
                                                    Ui.row
                                                        [ Ui.spacing 8 ]
                                                        [ CustomEmoji.viewHelper "1.1em" "0" emoji Sticker.LoopForever
                                                            |> Ui.html
                                                            |> Ui.el [ Ui.Font.size 24, Ui.width Ui.shrink ]
                                                        , Ui.text (":" ++ CustomEmoji.emojiNameToString emoji.name ++ ":")
                                                        ]
                                                        |> helper False

                                                Nothing ->
                                                    Ui.el [ Ui.Font.size 24, Ui.Font.italic ] (Ui.text "Emoji missing")
                                                        |> helper False
                                )
                                ( [], 0, 0 )
                                (emojiDropdownList isMobile emojiSoFar availableCustomEmojis availableStickers local.localUser emojiData2)
                    in
                    dropdownContainer nameSoFar dropdown height (List.reverse rows)

                Nothing ->
                    dropdownContainer nameSoFar dropdown 40 [ Ui.el [ Ui.height (Ui.px 40) ] (Ui.text "Loading emojis...") ]

        TimestampSoFar _ timestamp ->
            let
                rows : List (Element Msg)
                rows =
                    List.indexedMap
                        (\index timestamp2 ->
                            dropdownButton
                                isMobile
                                False
                                dropdown
                                dropdownButtonId
                                index
                                (Ui.text (RichText.timestampToString time local.localUser.timezone timestamp2))
                        )
                        (timestampDropdownList local.localUser.timezone time timestamp)

                dropdownViewHeight : Int
                dropdownViewHeight =
                    List.length rows * dropdownButtonHeight isMobile False
            in
            dropdownContainer nameSoFar dropdown dropdownViewHeight rows


dropdownContainer : NameSoFar -> MentionUserDropdown -> Int -> List (Element Msg) -> Element Msg
dropdownContainer nameSoFar dropdown contentHeight content =
    let
        headerHeight : number
        headerHeight =
            20
    in
    Ui.column
        [ Ui.background MyUi.background2
        , MyUi.blockClickPropagation PressedPingDropdownContainer
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.Font.color MyUi.font2
        , Ui.move
            { x = round dropdown.inputElement.x
            , y = round (dropdown.inputElement.y - (toFloat contentHeight + headerHeight) + 1)
            , z = 0
            }
        , Ui.width (Ui.px (round dropdown.inputElement.width))
        , Ui.height (Ui.px (contentHeight + headerHeight))
        , Ui.clip
        , Ui.roundedWith { topLeft = 8, topRight = 8, bottomLeft = 0, bottomRight = 0 }

        --, Ui.Shadow.shadows [ { x = 0, y = 1, size = 0, blur = 4, color = Ui.rgba 0 0 0 0.2 } ]
        ]
        [ Ui.el
            [ Ui.Font.size 14, Ui.Font.bold, Ui.paddingXY 8 0, Ui.height (Ui.px headerHeight) ]
            (Ui.text
                (case nameSoFar of
                    NameSoFar _ ->
                        mentionUserText

                    EmojiSoFar _ ->
                        addStickerOrEmojiText

                    TimestampSoFar _ _ ->
                        addTimestampText
                )
            )
        , Ui.column [] content
        ]


dropdownButtonHeight : Bool -> Bool -> number
dropdownButtonHeight isMobile isLarge =
    if isLarge then
        if isMobile then
            80

        else
            50

    else if isMobile then
        50

    else
        30


dropdownButton : Bool -> Bool -> MentionUserDropdown -> (Int -> HtmlId) -> Int -> Element Msg -> Element Msg
dropdownButton isMobile isLarge dropdown dropdownButtonId index content =
    MyUi.elButton
        (dropdownButtonId index)
        (PressedDropdownItem index)
        [ Ui.Events.onMouseDown (PressedDropdownItem index)
        , MyUi.touchPress (PressedDropdownItem index)
        , Ui.paddingXY 8 0
        , Ui.contentCenterY
        , MyUi.hover isMobile [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        , Ui.height (Ui.px (dropdownButtonHeight isMobile isLarge))
        , Ui.Anim.focused (Ui.Anim.ms 100) [ Ui.Anim.backgroundColor MyUi.background3 ]
        , if dropdown.dropdownIndex == index then
            Ui.background MyUi.background3

          else
            Ui.noAttr
        , Html.Events.on
            "keydown"
            (Json.Decode.field "key" Json.Decode.string
                |> Json.Decode.andThen
                    (\key ->
                        if key == "ArrowDown" then
                            Json.Decode.succeed (TypedArrowInDropdown (index + 1))

                        else if key == "ArrowUp" then
                            Json.Decode.succeed (TypedArrowInDropdown (index - 1))

                        else
                            Json.Decode.fail ""
                    )
            )
            |> Ui.htmlAttribute
        ]
        content
