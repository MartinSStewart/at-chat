module Emoji exposing (Emoji(..), emojis, fromDiscord, toString, view)

import Discord
import Hex
import Json.Decode
import Set exposing (Set)
import Ui
import Ui.Font


emojis : List Emoji
emojis =
    """😀 😃 😄 😁 😆 😅 😂 🤣 ☺️ 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙 😚 😋 😛 😝 😜 🤪 🤨 🧐 🤓 😎 🤩 🥳 😏 😒 😞 😔 😟 😕 🙁 ☹️ 😣 😖 😫 😩 🥺 😢 😭 😤 😠 😡 🤬 🤯 😳 🥵 🥶 😱 😨 😰 😥 😓 🤗 🤔 🤭 🤫 🤥 😶 😐 😑 😬 🙄 😯 😦 😧 😮 😲 🥱 😴 🤤 😪 😵 🤐 🥴 🤢 🤮 🤧 😷 🤒 🤕 🤑 🤠 😈 👿 👹 👺 🤡 💩 👻 💀 ☠️ 👽 👾 🤖 🎃 😺 😸 😹 😻 😼 😽 🙀 😿 😾 👋 👐 🙌 👏 🤝 👍 👎 👊 ✊ 🤛 🤜 🤞 ✌️ 🤟 🤘 👌 🤏 👈 👉 👆 👇 ☝️ ✋ 🤚 🖐️ 🖖 👋 🤙 💪 🦾 🖕 ✍️ 🙏 🦶 🦵 🦿 💄 💋 👄 🦷 👅 👂 🦻 👃 👣 👁️ 👀 🧠 🗣️ 👤 👥 🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐽 🐸 🐵 🙈 🙉 🙊 🐒 🐔 🐧 🐦 🐤 🐣 🐥 🦆 🦅 🦉 🦇 🐺 🐗 🐴 🦄 🐝 🐛 🦋 🐌 🐞 🐜 🦟 🦗 🕷️ 🕸️ 🦂 🐢 🐍 🦎 🦖 🦕 🐙 🦑 🦐 🦞 🦀 🐡 🐠 🐟 🐬 🐳 🐋 🦈 🐊 🐅 🐆 🦓 🦍 🦧 🐘 🦛 🦏 🐪 🐫 🦒 🦘 🐃 🐂 🐄 🐎 🐖 🐏 🐑 🦙 🐐 🦌 🐕 🐩"""
        |> String.split " "
        |> List.map UnicodeEmoji


{-| OpaqueVariants
-}
type Emoji
    = UnicodeEmoji String


toString : Emoji -> String
toString emoji =
    case emoji of
        UnicodeEmoji text ->
            text


view : Emoji -> Ui.Element msg
view emoji =
    case emoji of
        UnicodeEmoji text ->
            Ui.el [ Ui.Font.size 20 ] (Ui.text text)


fromDiscord : Discord.EmojiData -> Emoji
fromDiscord emoji =
    case emoji.type_ of
        Discord.UnicodeEmojiType string ->
            UnicodeEmoji string

        Discord.CustomEmojiType _ ->
            UnicodeEmoji "❓"


type alias EmojiData =
    { char : String, shortNames : List String, category : String }


decodeEmojiJson : Json.Decode.Decoder EmojiData
decodeEmojiJson =
    Json.Decode.map3
        EmojiData
        (Json.Decode.field "non_qualified" Json.Decode.string
            |> Json.Decode.andThen
                (\code ->
                    case Hex.fromString code of
                        Ok code2 ->
                            Char.fromCode code2 |> String.fromChar |> Json.Decode.succeed

                        Err _ ->
                            Json.Decode.fail ("Invalid emoji code: " ++ code)
                )
        )
        (Json.Decode.field "short_names" (Json.Decode.list Json.Decode.string))
        (Json.Decode.field "category" Json.Decode.string)
