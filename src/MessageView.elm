module MessageView exposing (MessageViewMsg(..), ReactionsHover(..), isPressMsg, miniView, profileImagePaddingRight, reactionEmojiButtonContent, reactionEmojiView, reactionsMiniView, reactionsMiniViewNearEdge)

import Coord exposing (Coord)
import CssPixels exposing (CssPixels)
import CustomEmoji exposing (CustomEmojiData)
import Date exposing (Date)
import Discord
import Duration exposing (Duration)
import Effect.Browser.Dom as Dom exposing (HtmlId)
import Emoji exposing (CachedEmojiData, EmojiOrCustomEmoji(..))
import Html exposing (Html)
import Html.Attributes
import Icons
import Id exposing (CustomEmojiId, Id, UserId)
import Json.Decode
import List.Nonempty exposing (Nonempty)
import MyUi
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import PersonName exposing (PersonName)
import Point2d exposing (Point2d)
import RichText
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Sticker exposing (AnimationMode(..))
import Touch exposing (ScreenCoordinate, Touch)
import Ui exposing (Element)
import Ui.Anim
import Ui.Events
import Ui.Font
import Ui.Prose
import Ui.Shadow
import Url exposing (Url)
import User exposing (FrontendCurrentUser)


type MessageViewMsg
    = MessageView_PressedSpoiler Int
    | MessageView_PressedNonWhitelistLink Url
    | MessageView_PressedImage RichText.PressedImageData
    | MessageView_MouseEnteredMessage
    | MessageView_MouseExitedMessage
    | MessageView_TouchStart Duration Bool (Maybe String) (Maybe String) (NonemptyDict Int Touch)
    | MessageView_AltPressedMessage Bool (Maybe String) (Maybe String) (Coord CssPixels)
    | MessageView_PressedReactionEmoji_Remove EmojiOrCustomEmoji
    | MessageView_PressedReactionEmoji_Add EmojiOrCustomEmoji
    | MessageView_PressedReplyLink
    | MessageViewMsg_PressedShowReactionEmojiSelector
    | MessageViewMsg_PressedEditMessage
    | MessageViewMsg_PressedReply
    | MessageViewMsg_PressedShowFullMenu Bool (Coord CssPixels)
    | MessageView_PressedViewThreadLink
    | MessageView_NoOp
    | MessageViewMsg_PressedReactionEmoji EmojiOrCustomEmoji
    | MessageViewMsg_PressedCallStartedCard
    | MessageViewMsg_PressedGameStartedCard
    | MessageView_PressedUserIconAnchor (Point2d CssPixels ScreenCoordinate) ( Float, Float )
    | MessageView_PressedTimestamp (Point2d CssPixels ScreenCoordinate) ( Float, Float )
    | MessageView_PressedDateDivider Date (Point2d CssPixels ScreenCoordinate) ( Float, Float )
    | MessageView_PressedCardAnchor (Point2d CssPixels ScreenCoordinate) ( Float, Float )
    | MessageView_PressedUserIconButton (Id UserId)
    | MessageView_PressedDiscordUserIconButton (Discord.Id Discord.UserId)


isPressMsg : MessageViewMsg -> Bool
isPressMsg msg =
    case msg of
        MessageView_PressedSpoiler _ ->
            True

        MessageView_PressedNonWhitelistLink _ ->
            True

        MessageView_PressedImage _ ->
            True

        MessageView_MouseEnteredMessage ->
            False

        MessageView_MouseExitedMessage ->
            False

        MessageView_TouchStart _ _ _ _ _ ->
            False

        MessageView_AltPressedMessage _ _ _ _ ->
            True

        MessageView_PressedReactionEmoji_Remove _ ->
            True

        MessageView_PressedReactionEmoji_Add _ ->
            True

        MessageView_PressedReplyLink ->
            True

        MessageViewMsg_PressedShowReactionEmojiSelector ->
            True

        MessageViewMsg_PressedEditMessage ->
            True

        MessageViewMsg_PressedReply ->
            True

        MessageViewMsg_PressedShowFullMenu _ _ ->
            True

        MessageView_PressedViewThreadLink ->
            True

        MessageView_NoOp ->
            False

        MessageViewMsg_PressedReactionEmoji _ ->
            True

        MessageViewMsg_PressedCallStartedCard ->
            True

        MessageViewMsg_PressedGameStartedCard ->
            True

        MessageView_PressedUserIconAnchor _ _ ->
            True

        MessageView_PressedTimestamp _ _ ->
            True

        MessageView_PressedDateDivider _ _ _ ->
            True

        MessageView_PressedCardAnchor _ _ ->
            True

        MessageView_PressedUserIconButton _ ->
            True

        MessageView_PressedDiscordUserIconButton _ ->
            True


reactionEmojiButtonContent : SeqDict (Id CustomEmojiId) CustomEmojiData -> EmojiOrCustomEmoji -> Html msg
reactionEmojiButtonContent customEmojis emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji emoji2 ->
            Html.div
                [ Html.Attributes.style "font-size" "20px"
                , Html.Attributes.style "transform" "translateY(-3px)"
                ]
                [ Emoji.toString emoji2 |> Html.text ]

        EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
            CustomEmoji.view "1.1em" "0.2em" customEmojiId customEmojis LoopAFewTimesOnLoad


miniView : FrontendCurrentUser -> Bool -> Bool -> SeqSet (Id CustomEmojiId) -> SeqDict (Id CustomEmojiId) CustomEmojiData -> Element MessageViewMsg
miniView user isThreadStarter canEdit availableCustomEmojis customEmojis =
    miniViewContainer
        -48
        (recentEmojiButtons user availableCustomEmojis customEmojis
            ++ [ miniButton
                    (Dom.id "miniView_showReactionEmojiSelector")
                    MessageViewMsg_PressedShowReactionEmojiSelector
                    "Add reaction"
                    Icons.smile
               , if canEdit then
                    miniButton
                        (Dom.id "miniView_editMessage")
                        MessageViewMsg_PressedEditMessage
                        "Edit message"
                        Icons.pencil

                 else
                    Ui.none
               , if isThreadStarter then
                    Ui.none

                 else
                    miniButton
                        (Dom.id "miniView_reply")
                        MessageViewMsg_PressedReply
                        "Reply"
                        Icons.reply
               , miniButtonWithPosition
                    (Dom.id "miniView_showFullMenu")
                    (MessageViewMsg_PressedShowFullMenu isThreadStarter)
                    Icons.dotDotDot
               ]
        )


reactionsMiniView :
    FrontendCurrentUser
    -> SeqSet (Id CustomEmojiId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> Element MessageViewMsg
reactionsMiniView user availableCustomEmojis customEmojis =
    miniViewContainer
        -48
        (recentEmojiButtons user availableCustomEmojis customEmojis
            ++ [ miniButton
                    (Dom.id "miniView_showReactionEmojiSelector")
                    MessageViewMsg_PressedShowReactionEmojiSelector
                    "Add reaction"
                    Icons.smile
               ]
        )


reactionsMiniViewNearEdge :
    FrontendCurrentUser
    -> SeqSet (Id CustomEmojiId)
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> Element MessageViewMsg
reactionsMiniViewNearEdge user availableCustomEmojis customEmojis =
    miniViewContainer
        -8
        (recentEmojiButtons user availableCustomEmojis customEmojis
            ++ [ miniButton
                    (Dom.id "miniView_showReactionEmojiSelector")
                    MessageViewMsg_PressedShowReactionEmojiSelector
                    "Add reaction"
                    Icons.smile
               ]
        )


{-| Shortcuts for the emojis this user reaches for most often, so the common reactions are
one press away instead of a trip through the emoji selector.
-}
recentEmojiButtons : FrontendCurrentUser -> SeqSet (Id CustomEmojiId) -> SeqDict (Id CustomEmojiId) CustomEmojiData -> List (Element MessageViewMsg)
recentEmojiButtons user availableCustomEmojis customEmojis =
    User.commonlyUsedEmojis availableCustomEmojis user
        |> List.take 3
        |> List.indexedMap
            (\index ( emoji, _ ) ->
                miniButton
                    (Dom.id ("miniView_emojiReact_" ++ String.fromInt index))
                    (MessageViewMsg_PressedReactionEmoji emoji)
                    ""
                    (reactionEmojiButtonContent customEmojis emoji)
            )


{-| The height of the menu, and the width of each of the buttons in it, which are square.
-}
miniButtonSize : number
miniButtonSize =
    36


miniViewContainer : Int -> List (Element MessageViewMsg) -> Element MessageViewMsg
miniViewContainer xOffset buttons =
    Ui.row
        [ Ui.alignRight
        , Ui.background MyUi.background1
        , Ui.rounded 4
        , Ui.borderColor MyUi.border1
        , Ui.border 1
        , Ui.move { x = xOffset, y = -16, z = 0 }
        , Ui.height (Ui.px miniButtonSize)
        , Ui.clip
        ]
        buttons


{-| An icon in the menu is drawn at the size of the box it's given rather than at whatever
size the svg itself asks for (see the `mini-button-icon` rule in `MyUi.css`), since browsers
don't agree on how to size an svg that leaves its height to them.
-}
miniButtonIcon : Html msg -> Element msg
miniButtonIcon svg =
    Html.div
        [ Html.Attributes.class "mini-button-icon" ]
        [ svg ]
        |> Ui.html


miniButton : HtmlId -> msg -> String -> Html msg -> Element msg
miniButton htmlId onPress hoverText svg =
    Ui.el
        [ Ui.width (Ui.px miniButtonSize)
        , Ui.height (Ui.px miniButtonSize)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.id (Dom.idToString htmlId)
        , Ui.Events.stopPropagationOn "click" (Json.Decode.succeed ( onPress, True ))
        , Ui.pointer
        , MyUi.hoverText hoverText
        , MyUi.hover False [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        ]
        (miniButtonIcon svg)


miniButtonWithPosition : HtmlId -> (Coord CssPixels -> msg) -> Html msg -> Element msg
miniButtonWithPosition htmlId onPress svg =
    Ui.el
        [ Ui.width (Ui.px miniButtonSize)
        , Ui.height (Ui.px miniButtonSize)
        , Ui.contentCenterX
        , Ui.contentCenterY
        , Ui.htmlAttribute (Html.Attributes.attribute "role" "button")
        , Ui.id (Dom.idToString htmlId)
        , Ui.Events.stopPropagationOn "click"
            (Json.Decode.map2
                (\x y -> ( onPress (Coord.xy (round x) (round y)), True ))
                (Json.Decode.field "clientX" Json.Decode.float)
                (Json.Decode.field "clientY" Json.Decode.float)
            )
        , Ui.pointer
        , MyUi.hover False [ Ui.Anim.backgroundColor MyUi.hoverHighlight ]
        ]
        (miniButtonIcon svg)


{-| Whether the popup naming who reacted with an emoji comes up when the pointer is over
that reaction. It follows whether the thing the reactions belong to is hovered at all, so
that somewhere showing a message without its menu doesn't bring popups up either.
-}
type ReactionsHover
    = ReactionsHovered
    | ReactionsNotHovered


{-| Reaction buttons are a fixed width so that the popup above one can work out where
in the conversation its button sits, and from that which way it should open. A count
that has reached two digits gets a wider button.
-}
reactionButtonWidth : NonemptySet userId -> Int
reactionButtonWidth users =
    if NonemptySet.size users < 10 then
        52

    else
        60


reactionSpacing : number
reactionSpacing =
    4


{-| The gap between a message's profile image and the message itself.
-}
profileImagePaddingRight : number
profileImagePaddingRight =
    8


{-| The reaction row runs the full width of a message rather than being indented under
the message text the way `containerWidth` is, so it has the profile image's column to
itself as well.
-}
reactionRowWidth : Int -> Int
reactionRowWidth containerWidth =
    containerWidth + User.profileImageSize + profileImagePaddingRight


{-| Where each reaction button ends up, as an offset from the left of the reaction row,
once the row has wrapped. Buttons are laid out left to right and wrap onto a new line
when the next one no longer fits, which is what `Ui.wrap` does to them.
-}
reactionButtonOffsets : Int -> List Int -> List Int
reactionButtonOffsets rowWidth widths =
    List.foldl
        (\width ( nextOffset, offsets ) ->
            if nextOffset > 0 && nextOffset + width > rowWidth then
                ( width + reactionSpacing, 0 :: offsets )

            else
                ( nextOffset + width + reactionSpacing, nextOffset :: offsets )
        )
        ( 0, [] )
        widths
        |> Tuple.second
        |> List.reverse


{-| A reaction popup is much wider than the button it hangs off, so one near the edge of
the conversation used to hang off the side of it and give the conversation a horizontal
scrollbar. It opens away from whichever edge its button sits closest to instead, and is
capped at the room it has on that side so it can't reach past the edge either way.
-}
type ReactionPopupPlacement
    = -- Left edge lined up with the button's left edge
      PopupOpensRight { maxWidth : Int }
    | -- Right edge lined up with the button's right edge, so the arrow has to be
      -- measured from that edge instead to stay under the button's emoji
      PopupOpensLeft { maxWidth : Int, arrowFromRight : Int }


reactionPopupPlacement : Int -> Int -> Int -> ReactionPopupPlacement
reactionPopupPlacement rowWidth buttonWidth buttonOffset =
    let
        roomOnRight : Int
        roomOnRight =
            rowWidth - buttonOffset

        roomOnLeft : Int
        roomOnLeft =
            buttonOffset + buttonWidth
    in
    if roomOnRight >= roomOnLeft then
        PopupOpensRight { maxWidth = min reactionPopupMaxWidth roomOnRight }

    else
        PopupOpensLeft
            { maxWidth = min reactionPopupMaxWidth roomOnLeft
            , arrowFromRight =
                -- Mirrors the other arrow's offset across the button. Both are measured
                -- from the popup's padding box, which the button's border and the
                -- popup's own border inset by a pixel at each end.
                buttonWidth - 4 - reactionPopupArrowOffset - reactionPopupArrowWidth
            }


reactionPopupMaxWidth : number
reactionPopupMaxWidth =
    400


{-| How far the arrow sits from whichever edge of the popup is lined up with the
button, so that it lands under that button's emoji.
-}
reactionPopupArrowOffset : number
reactionPopupArrowOffset =
    11


reactionPopupArrowWidth : number
reactionPopupArrowWidth =
    16


reactionEmojiView :
    Maybe CachedEmojiData
    -> ReactionsHover
    -> userId
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> AnimationMode
    -> Int
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> Maybe (Element MessageViewMsg)
reactionEmojiView emojiData isHovered currentUserId customEmojis allUsers animationMode containerWidth reactions =
    if SeqDict.isEmpty reactions then
        Nothing

    else
        let
            entries : List ( EmojiOrCustomEmoji, NonemptySet userId )
            entries =
                SeqDict.toList reactions

            widths : List Int
            widths =
                List.map (\( _, users ) -> reactionButtonWidth users) entries

            rowWidth : Int
            rowWidth =
                reactionRowWidth containerWidth

            placements : List ReactionPopupPlacement
            placements =
                List.map2
                    (reactionPopupPlacement rowWidth)
                    widths
                    (reactionButtonOffsets rowWidth widths)
        in
        Ui.row
            [ Ui.wrap
            , Ui.spacing reactionSpacing
            ]
            (List.map2 Tuple.pair entries placements
                |> List.indexedMap
                    (\index ( ( emoji, users ), placement ) ->
                        let
                            hasReactedTo : Bool
                            hasReactedTo =
                                NonemptySet.member currentUserId users
                        in
                        (if hasReactedTo then
                            MyUi.rowButton
                                (Dom.id ("guild_removeReactionEmoji_" ++ String.fromInt index))
                                (MessageView_PressedReactionEmoji_Remove emoji)

                         else
                            MyUi.rowButton
                                (Dom.id "guild_addReactionEmoji")
                                (MessageView_PressedReactionEmoji_Add emoji)
                        )
                            [ Ui.rounded 8
                            , Ui.spacing 2
                            , Ui.background MyUi.background1
                            , Ui.paddingXY 4 0
                            , Ui.htmlAttribute (Html.Attributes.class "emoji-popup-container")
                            , Ui.borderColor
                                (if hasReactedTo then
                                    MyUi.highlightedBorder

                                 else
                                    MyUi.border1
                                )
                            , Ui.Font.color
                                (if hasReactedTo then
                                    MyUi.highlightedBorder

                                 else
                                    MyUi.font2
                                )
                            , Ui.border 1
                            , Ui.width (Ui.px (reactionButtonWidth users))
                            , Ui.contentCenterX
                            , Ui.Font.weight 500
                            , case isHovered of
                                ReactionsHovered ->
                                    reactionPopup emojiData customEmojis allUsers placement emoji users |> Ui.above

                                ReactionsNotHovered ->
                                    Ui.noAttr
                            ]
                            [ case emoji of
                                EmojiOrCustomEmoji_Emoji emoji2 ->
                                    Emoji.view emoji2

                                EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
                                    Ui.el
                                        [ CustomEmoji.view "1.1em" "0em" customEmojiId customEmojis animationMode
                                            |> Ui.html
                                            |> Ui.el [ Ui.centerY, Ui.move { x = 1, y = 0, z = 0 } ]
                                            |> Ui.inFront
                                        , Ui.Font.color (Ui.rgba 0 0 0 0)
                                        , Ui.Font.size 20
                                        ]
                                        (Ui.text "❓")
                            , reactionCountView users
                            ]
                    )
            )
            |> Just


{-| Past 99 there isn't room for the count in a reaction button, so it becomes an
infinity sign.
-}
reactionCountView : NonemptySet userId -> Element msg
reactionCountView users =
    if NonemptySet.size users > 99 then
        Ui.el
            [ Ui.width Ui.shrink, MyUi.noShrinking, Ui.centerY ]
            (Ui.html (Icons.infinity 16))

    else
        Ui.text (String.fromInt (NonemptySet.size users))


{-| Points down at the reaction's emoji from a popup whose left edge is lined up with
the reaction button.
-}
reactionPopupArrowFromLeft : Element msg
reactionPopupArrowFromLeft =
    Ui.html
        (Html.div
            [ Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "top" "calc(100% - 1px)"
            , Html.Attributes.style "left" (String.fromInt reactionPopupArrowOffset ++ "px")
            , Html.Attributes.style "width" "0"
            , Html.Attributes.style "height" "0"
            , Html.Attributes.style "border-left" "8px solid transparent"
            , Html.Attributes.style "border-right" "8px solid transparent"
            , Html.Attributes.style "border-top" ("8px solid " ++ MyUi.colorToStyle MyUi.background1)
            , Html.Attributes.style "pointer-events" "none"
            ]
            []
        )


{-| The same arrow for a popup lined up with the button's right edge instead. It is
measured from that edge so that it still lands under the reaction's emoji.
-}
reactionPopupArrowFromRight : Int -> Element msg
reactionPopupArrowFromRight arrowFromRight =
    Ui.html
        (Html.div
            [ Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "top" "calc(100% - 1px)"
            , Html.Attributes.style "right" (String.fromInt arrowFromRight ++ "px")
            , Html.Attributes.style "width" "0"
            , Html.Attributes.style "height" "0"
            , Html.Attributes.style "border-left" "8px solid transparent"
            , Html.Attributes.style "border-right" "8px solid transparent"
            , Html.Attributes.style "border-top" ("8px solid " ++ MyUi.colorToStyle MyUi.background1)
            , Html.Attributes.style "pointer-events" "none"
            ]
            []
        )


reactionPopup :
    Maybe CachedEmojiData
    -> SeqDict (Id CustomEmojiId) CustomEmojiData
    -> SeqDict userId { a | name : PersonName }
    -> ReactionPopupPlacement
    -> EmojiOrCustomEmoji
    -> NonemptySet userId
    -> Element MessageViewMsg
reactionPopup emojiData customEmojis allUsers placement emoji users =
    let
        names : Nonempty (Element msg)
        names =
            List.Nonempty.map
                (\userId ->
                    case SeqDict.get userId allUsers of
                        Just user ->
                            Ui.el
                                [ Ui.Font.color MyUi.font1, Ui.width Ui.shrink ]
                                (Ui.text (PersonName.toString user.name))

                        Nothing ->
                            Ui.text "<Missing>"
                )
                (NonemptySet.toNonemptyList users)

        nameCount =
            List.Nonempty.length names

        maybeEmojiName : Maybe String
        maybeEmojiName =
            case emoji of
                EmojiOrCustomEmoji_Emoji emoji2 ->
                    Maybe.andThen (\cached -> Emoji.firstShortName cached emoji2) emojiData
                        |> Maybe.map (\name -> ":" ++ name ++ ":")

                EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
                    SeqDict.get customEmojiId customEmojis
                        |> Maybe.map (\customEmoji -> ":" ++ CustomEmoji.emojiNameToString customEmoji.name ++ ":")

        namesParagraph : Element msg
        namesParagraph =
            Ui.Prose.paragraph
                [ Ui.Font.size 14, Ui.width Ui.fill ]
                (if nameCount > 10 then
                    let
                        visible =
                            List.Nonempty.take 8 names
                                |> List.Nonempty.toList
                                |> List.intersperse (Ui.text ", ")
                    in
                    visible ++ [ Ui.text ", and ", Ui.text (String.fromInt (nameCount - 8)), Ui.text " more" ]

                 else
                    case List.Nonempty.tail names of
                        [] ->
                            [ List.Nonempty.head names ]

                        [ two ] ->
                            [ List.Nonempty.head names, Ui.text " and ", two ]

                        rest ->
                            List.intersperse (Ui.text ", ") rest ++ [ Ui.text ", and ", List.Nonempty.head names ]
                )
    in
    Ui.row
        ([ Ui.htmlAttribute (Html.Attributes.class "emoji-popup")
         , Ui.width Ui.shrink
         , MyUi.htmlStyle "width" "max-content"
         , -- `Ui.above` puts the popup's wrapper flush against the top of the reaction
           -- button, so positioning it in there is what leaves the gap for the arrow
           -- and lines the popup up with one edge of the button or the other
           MyUi.htmlStyle "position" "absolute"
         , MyUi.htmlStyle "bottom" "8px"
         , Ui.background MyUi.background1
         , Ui.borderColor MyUi.border1
         , Ui.border 1
         , Ui.rounded 8
         , Ui.padding 8
         , Ui.spacing 8
         , Ui.Font.color MyUi.font3
         , MyUi.noPointerEvents
         , Ui.Shadow.shadows [ { x = 0, y = 2, size = 0, blur = 8, color = Ui.rgba 0 0 0 0.3 } ]
         , Ui.contentCenterY
         ]
            ++ (case placement of
                    PopupOpensRight { maxWidth } ->
                        [ MyUi.htmlStyle "left" "0"
                        , MyUi.htmlStyle "max-width" (String.fromInt maxWidth ++ "px")
                        , Ui.inFront reactionPopupArrowFromLeft
                        ]

                    PopupOpensLeft { maxWidth, arrowFromRight } ->
                        [ MyUi.htmlStyle "right" "0"
                        , MyUi.htmlStyle "max-width" (String.fromInt maxWidth ++ "px")
                        , Ui.inFront (reactionPopupArrowFromRight arrowFromRight)
                        ]
               )
        )
        [ case emoji of
            EmojiOrCustomEmoji_Emoji emoji2 ->
                Ui.el [ Ui.Font.size 40, Ui.width Ui.shrink, MyUi.noShrinking ] (Ui.text (Emoji.toString emoji2))

            EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
                Ui.el
                    [ Ui.width Ui.shrink, MyUi.noShrinking ]
                    (CustomEmoji.view "40px" "0em" customEmojiId customEmojis LoopForever |> Ui.html)
        , case maybeEmojiName of
            Just emojiName ->
                Ui.column
                    [ Ui.spacing 2 ]
                    [ Ui.el [ Ui.Font.size 14, Ui.Font.bold, Ui.Font.color MyUi.font1 ] (Ui.text emojiName)
                    , namesParagraph
                    ]

            Nothing ->
                namesParagraph
        ]
