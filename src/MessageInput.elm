module MessageInput exposing (..)

import Browser.Dom as Dom
import ChannelName
import Diff
import Duration
import Effect.Browser.Dom exposing (HtmlId)
import Effect.Command as Command
import Effect.Process as Process
import Effect.Task as Task
import Html
import Html.Attributes
import Html.Events
import Id exposing (ChannelId, GuildId, Id)
import Json.Decode
import LocalState exposing (FrontendChannel)
import RichText
import SeqDict
import String.Nonempty
import Ui exposing (Element)


type Msg
    = NoOp


channelTextInput : Id GuildId -> Id ChannelId -> FrontendChannel -> LoggedIn2 -> LocalState -> Element Msg
channelTextInput guildId channelId channel loggedIn local =
    let
        text : String
        text =
            case SeqDict.get ( guildId, channelId ) loggedIn.drafts of
                Just nonempty ->
                    String.Nonempty.toString nonempty

                Nothing ->
                    ""
    in
    Html.div
        [ Html.Attributes.style "display" "flex"
        , Html.Attributes.style "position" "relative"
        , Html.Attributes.style "min-height" "min-content"
        , Html.Attributes.style "width" "100%"
        ]
        [ Html.textarea
            [ Html.Attributes.style "color" "rgba(255,0,0,1)"
            , Html.Attributes.style "position" "absolute"
            , Html.Attributes.style "font-size" "inherit"
            , Html.Attributes.style "font-family" "inherit"
            , Html.Attributes.style "line-height" "inherit"
            , Html.Attributes.style "width" "calc(100% - 18px)"
            , Html.Attributes.style "height" "calc(100% - 2px)"
            , Dom.idToAttribute channelTextInputId
            , Html.Attributes.style "background-color" "rgb(32,40,70)"
            , Html.Attributes.style "border" "solid 1px rgb(60,70,100)"
            , Html.Attributes.style "border-radius" "4px"
            , Html.Attributes.style "resize" "none"
            , Html.Attributes.style "overflow" "hidden"
            , Html.Attributes.style "caret-color" "white"
            , Html.Attributes.style "padding" "8px"
            , Html.Events.onFocus (TextInputGotFocus channelTextInputId)
            , Html.Events.onBlur (TextInputLostFocus channelTextInputId)
            , case loggedIn.pingUser of
                Just { dropdownIndex } ->
                    Html.Events.preventDefaultOn
                        "keydown"
                        (Json.Decode.andThen
                            (\key ->
                                case key of
                                    "ArrowDown" ->
                                        Json.Decode.succeed ( PressedArrowInDropdown guildId (dropdownIndex + 1), True )

                                    "ArrowUp" ->
                                        Json.Decode.succeed ( PressedArrowInDropdown guildId (dropdownIndex - 1), True )

                                    "Enter" ->
                                        Json.Decode.succeed
                                            ( PressedPingUser guildId channelId dropdownIndex, True )

                                    _ ->
                                        Json.Decode.fail ""
                            )
                            (Json.Decode.field "key" Json.Decode.string)
                        )

                Nothing ->
                    Html.Events.preventDefaultOn
                        "keydown"
                        (Json.Decode.map2 Tuple.pair
                            (Json.Decode.field "shiftKey" Json.Decode.bool)
                            (Json.Decode.field "key" Json.Decode.string)
                            |> Json.Decode.andThen
                                (\( shiftHeld, key ) ->
                                    if key == "Enter" && not shiftHeld then
                                        Json.Decode.succeed ( PressedSendMessage guildId channelId, True )

                                    else
                                        Json.Decode.fail ""
                                )
                        )
            , Html.Events.onInput (TypedMessage guildId channelId)
            , Html.Attributes.value text
            ]
            []
        , Html.div
            [ Html.Attributes.style "pointer-events" "none"
            , Html.Attributes.style "padding" "0 9px 0 9px"
            , Html.Attributes.style "transform" "translateY(9px)"
            , Html.Attributes.style "white-space" "pre-wrap"
            , Html.Attributes.style "color"
                (if text == "" then
                    "rgb(180,180,180)"

                 else
                    "rgb(255,255,255)"
                )
            ]
            (case String.Nonempty.fromString text of
                Just nonempty ->
                    let
                        users =
                            LocalState.allUsers local
                    in
                    RichText.textInputView users (RichText.fromNonemptyString users nonempty)
                        ++ [ Html.text "\n" ]

                Nothing ->
                    [ "Write a message in #"
                        ++ ChannelName.toString channel.name
                        |> Html.text
                    ]
            )
        ]
        |> Ui.html


multilineUpdate :
    Id GuildId
    -> Id ChannelId
    -> HtmlId
    -> String
    -> String
    -> LoggedIn2
    -> LoadedFrontend
    -> ( LoggedIn2, Command FrontendOnly ToBackend Msg )
multilineUpdate guildId channelId multilineId text oldText loggedIn model =
    let
        oldAtCount : Int
        oldAtCount =
            List.length (String.indexes "@" oldText)

        atCount : Int
        atCount =
            List.length (String.indexes "@" text)

        typedAtSymbol : Maybe Int
        typedAtSymbol =
            if
                (atCount > oldAtCount)
                    && -- Detect if the user is pasting in text and if they are, abort the @mention dropdown
                       (String.length text - String.length oldText < 3)
            then
                case newAtSymbol oldText text of
                    Just { index } ->
                        let
                            previous =
                                String.slice (index - 1) index text
                        in
                        if index == 0 || previous == " " || previous == "\n" then
                            Just index

                        else
                            Nothing

                    Nothing ->
                        Nothing

            else
                Nothing
    in
    handleLocalChange
        model.time
        (if loggedIn.typingDebouncer then
            Local_MemberTyping model.time guildId channelId |> Just

         else
            Nothing
        )
        { loggedIn
            | pingUser =
                if oldAtCount > atCount then
                    Nothing

                else
                    loggedIn.pingUser
            , drafts =
                case String.Nonempty.fromString text of
                    Just nonempty ->
                        SeqDict.insert ( guildId, channelId ) nonempty loggedIn.drafts

                    Nothing ->
                        SeqDict.remove ( guildId, channelId ) loggedIn.drafts
            , typingDebouncer = False
        }
        (Command.batch
            [ case typedAtSymbol of
                Just index ->
                    Dom.getElement multilineId
                        |> Task.map
                            (\{ element } ->
                                { dropdownIndex = 0
                                , charIndex = index
                                , inputElement = element
                                }
                            )
                        |> Task.attempt GotPingUserPosition

                Nothing ->
                    Command.none
            , Process.sleep (Duration.seconds 1)
                |> Task.perform (\() -> DebouncedTyping)
            ]
        )


newAtSymbol : String -> String -> Maybe { index : Int }
newAtSymbol oldText text =
    List.foldl
        (\change state ->
            case change of
                Diff.Added char ->
                    if char == '@' then
                        { index = state.index + 1
                        , foundAtSymbol = Just { index = state.index }
                        }

                    else
                        case state.foundAtSymbol of
                            Just found ->
                                { index = state.index + 1
                                , foundAtSymbol = Just { index = found.index }
                                }

                            Nothing ->
                                { index = state.index + 1
                                , foundAtSymbol = state.foundAtSymbol
                                }

                _ ->
                    { index = state.index + 1
                    , foundAtSymbol = state.foundAtSymbol
                    }
        )
        { index = 0, foundAtSymbol = Nothing }
        (Diff.diff (String.toList oldText) (String.toList text))
        |> .foundAtSymbol
