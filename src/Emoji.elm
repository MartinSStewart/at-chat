module Emoji exposing (Emoji(..), codec, emojis, fromDiscord, toString, view)

import Codec exposing (Codec)
import Discord
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


codec : Codec Emoji
codec =
    Codec.custom
        (\unicodeEmojiEncoder value ->
            case value of
                UnicodeEmoji arg0 ->
                    unicodeEmojiEncoder arg0
        )
        |> Codec.variant1 "UnicodeEmoji" UnicodeEmoji Codec.string
        |> Codec.buildCustom
